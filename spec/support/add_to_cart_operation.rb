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
