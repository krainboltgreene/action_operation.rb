require "spec_helper"

RSpec.describe ActionOperation do
  let(:operation) { DocumentUploadOperation.new(raw: arguments) }

  before do
    allow(operation).to receive(:logger)
  end

  describe "#call" do
    subject { operation.call }

    context "with the right arguments" do
      let(:arguments) {{document: Document.new}}

      it "calls the around steps callback" do
        expect(operation).to receive(:logger).twice

        subject
      end

      it "works" do
        expect(subject).to match(hash_including(document: a_kind_of(Document), location: "some.s3"))
      end

      context "drifting from s3" do
        before do
          allow(S3).to receive(:push).and_raise(StandardError, 'something')
        end

        it "works" do
          expect(subject).to match(hash_including(document: a_kind_of(Document), location: "some.azure"))
        end
      end

      context "drifting from s3 and azure" do
        before do
          allow(S3).to receive(:push).and_raise(StandardError, 'something')
          allow(Azure).to receive(:push).and_raise(StandardError, 'something')
        end

        it "works" do
          expect(subject).to match(hash_including(document: a_kind_of(Document), location: "some.spaces"))
        end
      end

      context "drifting from s3 and azure and spacs" do
        before do
          allow(S3).to receive(:push).and_raise(StandardError, 'something')
          allow(Azure).to receive(:push).and_raise(StandardError, 'something')
          allow(Spaces).to receive(:push).and_raise(StandardError, 'something')
        end

        it "works" do
          expect{subject}.to raise_exception(FailedUploadError)
        end
      end
    end
  end
end
