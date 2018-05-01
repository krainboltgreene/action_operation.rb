class AzureUploadOperation
  include ActionOperation

  task :upload

  state :upload do
    field :document, type: Types.Instance(Document)
  end
  step :upload do |state|
    begin
      fresh(document: state.document, location: Azure.push(state.document))
    rescue StandardError => exception
      raise FailedUploadError
    end
  end
end
