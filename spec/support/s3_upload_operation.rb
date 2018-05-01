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
