# frozen_string_literal: true

require "rails_helper"

RSpec.describe Document do
  describe "validations" do
    it "accepts a document with a PDF attached" do
      expect(attach_sample_pdf(build_document)).to be_valid
    end

    it "requires a title, a signer name and a signer email" do
      document = Document.new

      expect(document).not_to be_valid
      expect(document.errors.attribute_names).to include(:title, :signer_name, :signer_email)
    end

    it "rejects a malformed signer email" do
      expect(build_document(signer_email: "not-an-email")).not_to be_valid
    end

    it "rejects an attachment that is not a PDF" do
      document = attach_sample_pdf(build_document, content_type: "image/png")

      expect(document).not_to be_valid
      expect(document.errors[:file]).to be_present
    end
  end

  describe "#signed?" do
    it "is false while the signature is still awaiting the signer" do
      document = create_document
      document.signatures.create!(external_envelope_id: "MOCK-1", status: :issued)

      expect(document).not_to be_signed
    end

    it "is true once a signature is completed" do
      document = create_document
      document.signatures.create!(external_envelope_id: "MOCK-1", status: :signed, signed_at: Time.current)

      expect(document).to be_signed
    end

    it "ignores revoked signatures" do
      document = create_document
      document.signatures.create!(
        external_envelope_id: "MOCK-1", status: :signed, signed_at: Time.current, revoked_at: Time.current
      )

      expect(document).not_to be_signed
    end
  end

  describe "#revoke_pending_signatures!" do
    it "revokes in-flight requests so the flow can be restarted" do
      document = create_document
      pending = document.signatures.create!(external_envelope_id: "MOCK-1", status: :issued)

      document.revoke_pending_signatures!

      expect(pending.reload).to be_revoked
      expect(document.pending_signature).to be_nil
    end
  end
end
