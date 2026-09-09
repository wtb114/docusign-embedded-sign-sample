# frozen_string_literal: true

require "rails_helper"

RSpec.describe Signature do
  let(:document) { create_document }

  describe "validations" do
    it "requires the DocuSign envelope id" do
      signature = document.signatures.build(external_envelope_id: nil)

      expect(signature).not_to be_valid
      expect(signature.errors[:external_envelope_id]).to be_present
    end

    it "requires signed_at once the status is signed" do
      signature = document.signatures.build(external_envelope_id: "MOCK-1", status: :signed)

      expect(signature).not_to be_valid
      expect(signature.errors[:signed_at]).to be_present
    end
  end

  describe "#complete!" do
    it "attaches the signed PDF and records the completion time" do
      signature = document.signatures.create!(external_envelope_id: "MOCK-1", status: :issued)

      freeze_time do
        signature.complete!(File.binread(DocumentFactory::SAMPLE_PDF))

        expect(signature).to be_signed
        expect(signature.signed_at).to eq(Time.current)
        expect(signature.file).to be_attached
        expect(signature.file.content_type).to eq("application/pdf")
      end
    end
  end

  describe "#revoke!" do
    it "soft deletes so the request history stays auditable" do
      signature = document.signatures.create!(external_envelope_id: "MOCK-1", status: :issued)

      signature.revoke!

      expect(signature).to be_revoked
      expect(signature.revoked_at).to be_present
      expect(described_class.active).not_to include(signature)
    end
  end
end
