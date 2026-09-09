# frozen_string_literal: true

require "rails_helper"

# Walks the whole round trip the way a browser does, including the redirect out
# to the signing session and back.
RSpec.describe "Signing flow" do
  describe "POST /documents" do
    it "creates a document and redirects to it" do
      expect {
        post documents_path, params: {
          document: {
            title: "Service Agreement",
            signer_name: "Jane Doe",
            signer_email: "jane.doe@example.com",
            file: fixture_file_upload(DocumentFactory::SAMPLE_PDF, "application/pdf")
          }
        }
      }.to change(Document, :count).by(1)

      expect(response).to redirect_to(Document.last)
    end

    it "re-renders the form when the input is invalid" do
      post documents_path, params: { document: { title: "", signer_name: "", signer_email: "nope" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "the round trip" do
    let(:document) { create_document }

    it "signs the document and makes the signed PDF available" do
      post sign_document_path(document)
      expect(response).to redirect_to(%r{/mock_docusign/MOCK-})

      envelope_id = document.pending_signature.external_envelope_id
      post complete_mock_docusign_path(envelope_id), params: { return_url: signed_document_url(document) }

      follow_redirect!
      follow_redirect!

      expect(document.reload).to be_signed
      expect(flash[:notice]).to eq(I18n.t("flash.signing_completed"))

      get download_document_path(document)
      expect(response).to have_http_status(:redirect)
    end

    # The event parameter travels through the browser, so it can only drive the
    # message. Anything else must come from the API.
    it "does not mark the document signed when the signer cancels" do
      post sign_document_path(document)

      get signed_document_path(document, event: "cancel")

      expect(document.reload).not_to be_signed
      expect(flash[:alert]).to eq(I18n.t("docusign.events.cancel"))
    end

    it "does not trust a forged signing_complete event" do
      post sign_document_path(document)

      # The envelope was never completed on the DocuSign side.
      get signed_document_path(document, event: "signing_complete")

      expect(document.reload).not_to be_signed
      expect(flash[:alert]).to eq(I18n.t("flash.not_completed_yet"))
    end
  end
end
