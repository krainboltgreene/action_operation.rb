class DocumentUploadOperation < ApplicationOperation
  task :upload_to_s3
  task :upload_to_azure, required: false
  task :upload_to_spaces, required: false
  task :publish
  catch :retry, exception: FailedUploadError
  catch :reraise

  def around_steps(**)
    logger("around_steps/before")
    yield.tap do
      logger("around_steps/after")
    end
  end

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

  def logger(message)
    puts(message)
  end
end
