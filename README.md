# action_operation

  - [![Build](http://img.shields.io/travis-ci/krainboltgreene/action_operation.rb.svg?style=flat-square)](https://travis-ci.org/krainboltgreene/action_operation.rb)
  - [![Downloads](http://img.shields.io/gem/dtv/action_operation.svg?style=flat-square)](https://rubygems.org/gems/action_operation)
  - [![Version](http://img.shields.io/gem/v/action_operation.svg?style=flat-square)](https://rubygems.org/gems/action_operation)


A simple set of right-to-left operations, similar to many other gems out there like [trailblazer operations](http://trailblazer.to/gems/operation/2.0/index.html).


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
  catch :notify, exception: ProductMissingFromCartItemError
  catch :reraise

  schema :check_for_missing_product do
    field :cart_item, type: Types.Instance(CartItem)
  end
  def check_for_missing_product(state:)
    raise ProductMissingFromCartItemError if state.cart_item.product.nil?
  end

  schema :carbon_copy_cart_item do
    field :cart_item, type: Types.Instance(CartItem)
  end
  def carbon_copy_cart_item(state:)
    state.cart_item.carbon_copy
  end

  schema :lock do
    field :cart_item, type: Types.Instance(CartItem)
  end
  def lock(state:)
    GlobalLock.(resource: state.cart_item, expires_in: 15.minutes)
  end

  schema :persist do
    field :cart_item, type: Types.Instance(CartItem)
  end
  def persist(state:)
    CartItem.transaction do
      state.cart_item.save!
    end

    fresh(state: {current_account: state.cart_item.owner, cart_item: state.cart_item})
  end

  schema :publish do
    field :cart_item, type: Types.Instance(CartItem)
    field :current_account, type: Types.Instance(Account)
  end
  def publish(state:)
    CartItemPickedMessage.(
      to: state.current_account,
      subject: state.cart_item,
      via: :pubsub,
      deliver: :later
    )
  end

  def notify(exception:, **)
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
  catch :notify, exception: ProductMissingFromCartItemError
  catch :reraise

  # ...
end
```

These are the steps our process will take. Each `task` call is *in the order it is listed*, which means that `check_for_missing_product` will happen before `carbon_copy_cart_item`. Each `catch` is also *in the order it is listed*, but they only trigger when one of the `task` raises an exception. In this case, we only want to `notify` when there's something seriously wrong!

Finally, before we leave notice the `reraise` error step. This is built in to the operation layer so that you can easily pass the buck to whomever owns the action currently.

Okay, so on to our first step:

``` ruby
class AddToCartOperation
  # ...

  schema :check_for_missing_product do
    field :cart_item, type: Types.Instance(CartItem)
  end
  def check_for_missing_product(state:)
    raise ProductMissingFromCartItemError if state.cart_item.product.nil?
  end

  # ...
end
```

There's two things we want to talk about there and the first is `schema`. It defines the shape of the *immutable* state that the step will receive. We use [smart_params](https://github.com/krainboltgreene/smart_params.rb) which means each field is typed with [dry-types](https://github.com/dry-rb/dry-types). Read up on both of those libraries for more fine grained control over your data. Second is the step definition itself which provides a `state` object that is based on the schema by the same name. You have four choices on what you can do in a step. You can:

  - Return any value, which will simply proceed to the next step.
  - Raise an exception, which will move you into the left track (that uses `catch` steps)
  - Return a fresh state, which will be described below
  - Return a drift instruction, which will be described below

### Fresh State

Sometimes you want to pass different state to all steps after. We provide the `fresh()` function for this very purpose:

``` ruby
class AddToCartOperation
  # ...

  schema :persist do
    field :cart_item, type: Types.Instance(CartItem)
  end
  def persist(state:)
    CartItem.transaction do
      state.cart_item.save!
    end

    fresh(state: {current_account: state.cart_item.owner, cart_item: state.cart_item})
  end

  # ...
end
```


### Drifting

Alright, so lets say you have a business requirement to upload important documents to the cloud. You have multiple providers (S3, Azure, and DigitalOcean Spaces) and you want to make sure it gets pushed to at least one. First we define how to talk to S3:

``` ruby
class S3UploadOperation
  include ActionOperation

  task :upload

  schema :upload do
    field :document, type: Types.Instance(Document)
  end
  def upload(state:)
    fresh(state: {document: state.document, location: S3.push(state.document)})
  rescue StandardError => exception
    raise FailedUploadError
  end
end
```

Now we define the controlling operation:

``` ruby
class DocumentUploadOperation < ApplicationOperation
  task :upload_to_s3
  task :upload_to_azure, required: false
  task :upload_to_spaces, required: false
  task :publish
  catch :retry, exception: FailedUploadError
  catch :reraise

  schema :upload_to_s3 do
    field :document, type: Types.Instance(Document)
  end
  def upload_to_s3(state:)
    fresh(state: S3UploadOperation.(document: state.document))
  end

  schema :upload_to_azure do
    field :document, type: Types.Instance(Document)
  end
  def upload_to_azure(state:)
    fresh(state: AzureUploadOperation.(document: state.document))
  end

  schema :upload_to_spaces do
    field :document, type: Types.Instance(Document)
  end
  def upload_to_spaces(state:)
    fresh(state: SpacesUploadOperation.(document: state.document))
  end

  schema :publish do
    field :document, type: Types.Instance(Document)
    field :location, type: Types::Strict::String
  end
  def publish(state:)
    DocumentSuccessfullyUploadedMessage.(
      to: state.document.owner,
      subject: state.location,
      via: :pubsub,
      deliver: :later
    )
  end

  def retry(exception:, step:, **)
    case step.name
    when :upload_to_s3 then drift(to: :upload_to_azure)
    when :upload_to_azure then drift(to: :upload_to_spaces)
    end
  end
end
```

So here's how this works:

  1. First we call `upload_to_s3` which talks to `S3UploadOperation`, but for some reason this fails which bubbles up a specific exception that we catch with `DocumentUploadOperation#retry`
  2. `retry` looks at the last known step and then drifts to `upload_to_azure`, which functions just like above.
  3. Then somehow we fail to upload to Azure, so we repeat and retry with DigitalOcean Spaces.
  4. We fail to even upload that, which means the next catch step gets called (`reraise()`) giving control back to the owner of the operation

However, if it finishes successfully we get to push a notification to the document owner in `publish()`.


### Callbacks

Sometimes we want to make sure an operation or it's individual parts are wrapped in safety measures, like a transaction or a timeout. You can achieve these with special built in instance methods. I'll show you each one and why you would use it.

To start, the highest wrapper is `around_steps`, which wraps around both tasks and catches. A good use for this is

``` ruby
class AddProductToCart < ApplicationOperation
  def around_steps(raw:)
    Rails.logger.tagged("operation-id=#{SecureRandom.uuid}") do
      Rails.logger.debug("Started adding cart to product operation with (#{raw.to_json})")

      yield
    end
  end
end
```

Here we're making sure every log we write will be tagged with a unique identifier for the entire operation, an extremely valuable option for debugging. The `around_steps` hook will be told about the raw data it receives in the call (`AddProductToCart.({cart: current_cart, product: product})`).

While `around_steps` is on the entire operation, you might want individual wrapping. Let me present: `around_step`!

``` ruby
class AddProductToCart < ApplicationOperation
  def around_step(step:, **)
    Rails.logger.tagged("step-id=#{SecureRandom.uuid}") do
      yield
    end
  end
end
```

This `around_step` will give you a per-step unique id tag for all logs in a step, another fantastic tool in debugging. This hook will be told of the `Task|Catch` object which responds to `#name` and `#receiver`. Additionally a `Task` responds to `#required` and a `Catch` responds to `#exception`.

Finally, there are 4 other type specific hooks: `around_tasks`, `around_task`, `around_catches`, and `around_catch`. Here are example uses:


``` ruby
class AddProductToCart < ApplicationOperation
  def around_tasks(**)
    Timeout.new(30.seconds) do
      yield
    end
  end

  def around_task(step:, state:, **)
    Rails.logger.debug("Working on #{step.receiver}##{step.name} using (#{state.to_json})")

    Timeout.new(10.seconds) do
      ApplicationRecord.transaction do
        yield
      end
    end
  end
end
```


## Installing

Add this line to your application's Gemfile:

    gem "action_operation", "2.1.1"

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
