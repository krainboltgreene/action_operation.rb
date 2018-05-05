class ProductMissingFromCartItemError < StandardError

end

class FailedUploadError < StandardError
end

class Bugsnag
  def self.notify(exception)

  end
end

class S3
  def self.push(document)
    "some.s3"
  end
end

class Azure
  def self.push(document)
    "some.azure"
  end
end

class Spaces
  def self.push(document)
    "some.spaces"
  end
end

class Document
  def owner
    Account.new
  end
end

class CartItem
  def self.transaction
    yield
  end

  def owner
    Account.new
  end

  def product
    Product.new
  end

  def carbon_copy
    true
  end

  def save!
    true
  end
end

class Account
end

class Product
end

class GlobalLock
  def self.call(*keys)
    keys
  end
end

class CartItemPickedMessage
  def self.call(**keyword_arguments)
    new(keyword_arguments)
  end

  def initialize(**keyword_arguments)
  end

  def via_pubsub
    self
  end

  def deliver_later!
    true
  end
end

class DocumentSuccessfullyUploadedMessage
  def self.call(**keyword_arguments)
    new(keyword_arguments)
  end

  def initialize(**keyword_arguments)
  end
end
