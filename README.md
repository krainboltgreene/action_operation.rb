# action_operation

  - [![Build](http://img.shields.io/travis-ci/krainboltgreene/action_operation.rb.svg?style=flat-square)](https://travis-ci.org/krainboltgreene/action_operation.rb)
  - [![Downloads](http://img.shields.io/gem/dtv/action_operation.svg?style=flat-square)](https://rubygems.org/gems/action_operation)
  - [![Version](http://img.shields.io/gem/v/action_operation.svg?style=flat-square)](https://rubygems.org/gems/action_operation)


A simple set of right-to-left operations, similar to many other gems out there.


## Using

Alright, so you have some business logic you'd like to control in your application. You've found that putting in the controllers sucks, because an application is more than it's HTTP requests. You've found that putting in the model sucks, because there's not enough context and does too many things. You've found that "service classes" have no form or shape and get way too out of hand.

ActionOperation is here to help! This, like many others before and after, gives a concise way to describe a series of business requirements. It has as much context as you give it and only does the thing you need it to do. It can be used anywhere and everywhere.

First let's make our operation:

``` ruby
class AddToCartOperation
  include ActionOperation

  task :check_for_missing_product
  task :carbon_copy_cart_item
  task :lock
  task :persist
  task :publish
  error :notify, catch: ProductMissingFromCartItemError
  error :reraise

  state :check_for_missing_product do
    field :cart_item, type: Types.Instance(CartItem)
  end
  step :check_for_missing_product do |state|
    raise ProductMissingFromCartItemError if state.cart_item.product.nil?
  end

  state :carbon_copy_cart_item do
    field :cart_item, type: Types.Instance(CartItem)
  end
  step :carbon_copy_cart_item do |state|
    state.cart_item.carbon_copy
  end

  state :lock do
    field :cart_item, type: Types.Instance(CartItem)
  end
  step :lock do |state|
    GlobalLock.(state.cart_item.owner, state.cart_item, expires_in: 15.minutes)
  end

  state :persist do
    field :cart_item, type: Types.Instance(CartItem)
  end
  step :persist do |state|
    CartItem.transaction do
      state.cart_item.save!
    end

    fresh(current_account: state.cart_item.owner, cart_item: state.cart_item)
  end

  state :publish do
    field :cart_item, type: Types.Instance(CartItem)
    field :current_account, type: Types.Instance(Account)
  end
  step :publish do |state|
    CartItemPickedMessage.(subject: state.cart_item, to: state.current_account).via_pubsub.deliver_later!
  end

  step :notify do |exception|
    Bugsnag.notify(exception)
  end
end
```

There's a lot to take in here, so lets go through each point:

``` ruby
class AddToCartOperation
  # ...

  task :check_for_missing_product
  task :carbon_copy_cart_item
  task :lock
  task :persist
  task :publish
  error :notify, catch: ProductMissingFromCartItemError
  error :reraise

  # ...
end
```

These are the steps our process will take. Each `task` call is *in the order it is listed*, which means that `check_for_missing_product` will happen before `carbon_copy_cart_item`. Each `error` is also *in the order it is listed*, but they only trigger when one of the `task` raises an exception. In this case, we only want to `notify` when there's something seriously wrong!

Finally, before we leave, notice the `reraise` error step. This is built in to the operation layer so that you can easily pass the buck to whomever owns the action currently.

Okay, so on to our first step:

``` ruby
class AddToCartOperation
  # ...

  state :check_for_missing_product do
    field :cart_item, type: Types.Instance(CartItem)
  end
  step :check_for_missing_product do |state|
    raise ProductMissingFromCartItemError if state.cart_item.product.nil?
  end

  # ...
end
```

There's two things we want to talk about there and the first is `state`. It defines the shape of the *immutable* state that the step will receive. We use [smart_params](https://github.com/krainboltgreene/smart_params.rb) which means each field is typed with [dry-types](https://github.com/dry-rb/dry-types). Read up on both of those libraries for more fine grained control over your data.

Second is the `step` definition itself which provides a `state` object that is based on the schema defined above. You have four choices on what you can do in a `step`. You can:

  - Return any value, which will simply proceed to the next step.
  - Raise an exception, which will move you into the left track (that uses `error` steps)
  - Return a fresh state, which will be described below
  - Return a drift instruction, which will be described below

### Fresh State

Sometimes you want to change the data that is passed around after a step is completed. To achieve this functionality we provide the `fresh()` function:

``` ruby
class AddToCartOperation
  # ...

  step :persist do |state|
    CartItem.transaction do
      state.cart_item.save!
    end

    fresh(current_account: state.cart_item.owner, cart_item: state.cart_item)
  end

  # ...
end
```

This is the only way to "change" the shape of the state.


### Receivers

Sometimes you need to share functionality across multiple operations. You can do this via modules and inheritance like normal or you can use our specialized interface:

``` ruby
class DocumentUploadOperation
  include ActionOperation

  task :upload_to_s3, receiver: S3UploadOperation
end
```

This will give the `DocumentUploadOperation` a task that is on another operation! Sometimes that other task has a different name, so we also provide aliasing:

``` ruby
class DocumentUploadOperation
  include ActionOperation

  task :upload_to_s3, receiver: S3UploadOperation, :upload
end
```

So when `DocumentUploadOperation` finally gets to the `upload_to_s3` task it's actually calling the `S3UploadOperation` task called `upload`. More on why this is useful in the next section.


### Drifting

Alright, so lets say you have a business requirement to upload important documents to the cloud. You have multiple providers (S3, Azure, and DigitalOcean Spaces) and you want to make sure it gets pushed to at least one. Here's how you would write this:

``` ruby
class S3UploadOperation
  include ActionOperation

  task :upload

  state :upload do
    field :document, type: Types.Instance(Document)
  end
  step :upload do |state|
    fresh(document: state.document, location: S3.push(state.document))
  rescue StandardError => exception
    raise FailedUploadError
  end
end

```

``` ruby
class DocumentUploadOperation
  include ActionOperation

  task :upload_to_s3, receiver: S3UploadOperation, as: :upload
  task :upload_to_azure, receiver: AzureUploadOperation, as: :upload, required: false
  task :upload_to_spaces, receiver: SpacesUploadOperation, as: :upload, required: false
  task :publish
  error :retry, catch: FailedUploadError
  error :reraise

  step :retry do |exception, _, step|
    case step
    when :upload_to_s3 then drift(to: :upload_to_azure)
    when :upload_to_azure then drift(to: :upload_to_spaces)
    end
  end

  state :publish do
    field :document, type: Types.Instance(Document)
    field :location, type: Types::Strict::String
  end
  step :publish do |state|
    DocumentSuccessfullyUploadedMessage.(owner: state.document.owner, location: state.location).via_pubsub.deliver_later!
  end
end
```

So here's how this works:

  1. First we call `upload_to_s3`, which actually talks to `S3UploadOperation/upload`, but for some reason this fails and gets caught by `failed_upload`, which bubbles up a specific exception that we catch with `DocumentUploadOperation/retry`
  2. `retry` looks at the last known step and then drifts to `upload_to_azure`, which functions just like above.
  3. Then somehow we fail to upload to Azure, so we repeat and retry with DigitalOcean Spaces.
  4. We fail to even upload that, which means the next error step gets called (`reraise`) giving control back to the owner of the operation


However, if it finishes successfully we get to push a notification to the document owner in `finish`.


### Understanding the design

Each task is a map function wrapped in a HOC for handling the return data. The annotation of each task is `state -> mixed | state` and the HOC is `state -> (state -> mixed | state) -> state`. `error` is like a task, but instead: `exception -> mixed` wrapped in a HOC that matches `exception -> (exception -> mixed) -> exception`.


## Installing

Add this line to your application's Gemfile:

    gem "action_operation", "1.1.0"

And then execute:

    $ bundle

Or install it yourself with:

    $ gem install action_operation


## Contributing

  1. Read the [Code of Conduct](/CONDUCT.md)
  2. Fork it
  3. Create your feature branch (`git checkout -b my-new-feature`)
  4. Commit your changes (`git commit -am 'Add some feature'`)
  5. Push to the branch (`git push origin my-new-feature`)
  6. Create new Pull Request
