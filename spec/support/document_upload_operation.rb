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
