# frozen_string_literal: true

require "rails_helper"

RSpec.describe Docusign::SignService do
  let(:document) { create_document }
  let(:gateway)  { Docusign::MockGateway.new }
  let(:service)  { described_class.new(document: document, gateway: gateway) }
  let(:return_url) { "http://example.com/documents/#{document.id}/signed" }

  describe "#start_signing!" do
    it "creates an issued signature and returns the signing URL" do
      url = service.start_signing!(return_url: return_url)

      signature = document.pending_signature
      expect(signature).to be_issued
      expect(signature.external_envelope_id).to be_present
      expect(url).to include(signature.external_envelope_id)
    end

    it "refuses to start again once the document is signed" do
      sign_document

      expect { service.start_signing!(return_url: return_url) }
        .to raise_error(Docusign::InconsistentStateError)
    end

    it "refuses to start without a PDF" do
      document.file.purge

      expect { service.start_signing!(return_url: return_url) }
        .to raise_error(Docusign::Error, I18n.t("docusign.errors.pdf_missing"))
    end

    # Signing URLs expire within minutes, so restarting has to supersede the old
    # request rather than leave two live envelopes behind.
    it "revokes the previous request when the flow is restarted" do
      service.start_signing!(return_url: return_url)
      first = document.pending_signature

      service.start_signing!(return_url: return_url)

      expect(first.reload).to be_revoked
      expect(document.signatures.active.issued.count).to eq(1)
    end
  end

  describe "#finish_signing!" do
    it "returns nil while DocuSign has not marked the envelope completed" do
      service.start_signing!(return_url: return_url)

      expect(service.finish_signing!).to be_nil
      expect(document.reload).not_to be_signed
    end

    it "imports the signed PDF once the envelope is completed" do
      service.start_signing!(return_url: return_url)
      gateway.complete!(document.pending_signature.external_envelope_id)

      signature = service.finish_signing!

      expect(signature).to be_signed
      expect(signature.file).to be_attached
      expect(document.reload).to be_signed
    end

    it "raises when there is no request waiting to be completed" do
      expect { service.finish_signing! }
        .to raise_error(Docusign::InconsistentStateError)
    end
  end

  private def sign_document
    service.start_signing!(return_url: return_url)
    gateway.complete!(document.pending_signature.external_envelope_id)
    service.finish_signing!
    document.reload
  end
end
