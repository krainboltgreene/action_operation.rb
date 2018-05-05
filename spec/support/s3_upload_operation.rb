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
