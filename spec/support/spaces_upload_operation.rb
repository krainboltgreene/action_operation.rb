class SpacesUploadOperation
  include ActionOperation

  task :upload

  state :upload do
    field :document, type: Types.Instance(Document)
  end
  step :upload do |state|
    begin
      fresh(document: state.document, location: Spaces.push(state.document))
    rescue StandardError => exception
      raise FailedUploadError
    end
  end
end
