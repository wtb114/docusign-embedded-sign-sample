# frozen_string_literal: true

module Docusign
  # The signing workflow for a single document.
  #
  # There are only two steps:
  #
  #   start_signing!  creates the envelope and returns the signing URL
  #   finish_signing! confirms the outcome against the API and stores the signed PDF
  #
  # The important part is that the event parameter DocuSign appends to return_url
  # is never treated as proof. It arrives through the browser, so the envelope
  # status is fetched from the API before anything is written.
  class SignService
    EMAIL_SUBJECT = "Signature requested"

    attr_reader :document, :gateway

    def initialize(document:, gateway: Gateway.build)
      @document = document
      @gateway  = gateway
    end

    # Creates the signing request and returns the URL to redirect the signer to.
    def start_signing!(return_url:)
      raise InconsistentStateError, I18n.t("docusign.errors.already_signed") if document.signed?

      attachment = document.file
      raise Error, I18n.t("docusign.errors.pdf_missing") unless attachment.attached?

      # Supersede any in-flight request before creating a new envelope.
      document.revoke_pending_signatures!

      result = attachment.blob.open do |pdf|
        gateway.create_embedded_signing(
          pdf_path:   pdf.path,
          subject:    EMAIL_SUBJECT,
          signer:     signer_config,
          return_url: return_url
        )
      end

      document.signatures.create!(
        external_envelope_id:  result[:envelope_id],
        external_document_id:  EnvelopeCreator::DOCUMENT_ID,
        external_recipient_id: EnvelopeCreator::SIGNER_ID,
        docusign_user_id:      gateway.try(:docusign_user_id),
        status:                :issued
      )

      Rails.logger.info("[DocuSign] signing started document_id=#{document.id} envelope_id=#{result[:envelope_id]}")

      result[:url]
    rescue DocuSign_eSign::ApiError => exception
      ApiErrorLogger.log(exception, document: document)
      raise ApiError, I18n.t("docusign.errors.create_failed")
    end

    # Confirms the signature and imports the signed PDF.
    #
    # @return [Signature, nil] the completed signature, or nil if DocuSign has
    #   not marked the envelope completed yet
    def finish_signing!
      signature = document.pending_signature
      raise InconsistentStateError, I18n.t("docusign.errors.no_pending_signature") if signature.blank?

      return nil unless gateway.completed?(signature.external_envelope_id)

      signature.complete!(gateway.signed_pdf(signature.external_envelope_id))

      Rails.logger.info("[DocuSign] signing completed document_id=#{document.id} envelope_id=#{signature.external_envelope_id}")

      signature
    rescue DocuSign_eSign::ApiError => exception
      ApiErrorLogger.log(exception, document: document, signature: signature)
      raise ApiError, I18n.t("docusign.errors.fetch_failed")
    end

    private def signer_config
      SignerConfig.new(
        name:          document.signer_name,
        email:         document.signer_email,
        recipient_id:  EnvelopeCreator::SIGNER_ID,
        routing_order: EnvelopeCreator::ROUTING_ORDER,
        # Any application-side identifier works here. Its presence is what makes
        # the session embedded rather than email-based.
        client_user_id: document.id
      )
    end
  end
end
