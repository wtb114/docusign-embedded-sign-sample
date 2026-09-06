# frozen_string_literal: true

module Docusign
  # Gateway implementation backed by the real DocuSign eSignature API.
  class ApiGateway
    attr_reader :docusign_user_id

    def initialize(docusign_user_id: JwtClient.user_id)
      @docusign_user_id = docusign_user_id
    end

    def create_embedded_signing(pdf_path:, subject:, signer:, return_url:)
      creator.create_embedded_signing(
        pdf_path:   pdf_path,
        subject:    subject,
        signer:     signer,
        return_url: return_url
      )
    end

    def recipient_view_url(envelope_id:, signer:, return_url:)
      creator.create_recipient_view(envelope_id: envelope_id, signer: signer, return_url: return_url)
    end

    def completed?(envelope_id)
      creator.envelope_completed?(envelope_id)
    end

    def signed_pdf(envelope_id)
      creator.fetch_signed_pdf(envelope_id)
    end

    private def creator
      @creator ||= EnvelopeCreator.new(
        api_client: JwtClient.api_client(docusign_user_id: docusign_user_id)
      )
    end
  end
end
