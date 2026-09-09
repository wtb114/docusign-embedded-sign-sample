# frozen_string_literal: true

module Docusign
  # Creates DocuSign envelopes and issues embedded signing URLs.
  #
  # The embedded signing flow:
  #   1. Base64 the PDF into an envelope and send it (status "sent")
  #   2. Ask for a RecipientView, which returns a short-lived signing URL
  #   3. Redirect the signer there; DocuSign sends them back to return_url
  #
  # The signer needs a client_user_id for this to be embedded rather than
  # DocuSign emailing them a link.
  class EnvelopeCreator
    DOCUMENT_ID   = "1"
    SIGNER_ID     = "1"
    ROUTING_ORDER = "1"

    def initialize(api_client:)
      @envelopes = DocuSign_eSign::EnvelopesApi.new(api_client)
    end

    # @return [Hash] { envelope_id:, url: }
    def create_embedded_signing(pdf_path:, subject:, signer:, return_url:)
      envelope = @envelopes.create_envelope(
        JwtClient.account_id,
        build_envelope_definition(pdf_path: pdf_path, subject: subject, signer: signer)
      )

      {
        envelope_id: envelope.envelope_id,
        url: create_recipient_view(
          envelope_id: envelope.envelope_id,
          signer:      signer,
          return_url:  return_url
        )
      }
    end

    # Issues a fresh signing URL for an existing envelope.
    #
    # Signing URLs expire within minutes, so a restarted flow asks for a new URL
    # rather than building another envelope.
    def create_recipient_view(envelope_id:, signer:, return_url:)
      view_request = DocuSign_eSign::RecipientViewRequest.new(
        returnUrl:            return_url,
        authenticationMethod: "none",
        userName:             signer.name,
        email:                signer.email,
        clientUserId:         signer.client_user_id.to_s
      )

      @envelopes.create_recipient_view(JwtClient.account_id, envelope_id, view_request).url
    end

    def envelope_completed?(envelope_id)
      status = @envelopes.get_envelope(JwtClient.account_id, envelope_id).status
      Rails.logger.info("[DocuSign] envelope status envelope_id=#{envelope_id} status=#{status}")
      status == "completed"
    end

    # Downloads the signed PDF.
    #
    # Passing "combined" as the document id returns every document in the envelope
    # merged with the signing certificate page, which is the copy worth keeping as
    # evidence. The SDK hands back a Tempfile, so it is read into bytes here.
    def fetch_signed_pdf(envelope_id)
      options = DocuSign_eSign::GetDocumentOptions.new
      options.certificate = "true"
      options.language    = I18n.locale.to_s

      pdf = @envelopes.get_document(JwtClient.account_id, "combined", envelope_id, options)
      unless pdf.is_a?(Tempfile)
        raise ApiError, I18n.t("docusign.errors.unexpected_pdf_format", klass: pdf.class)
      end

      File.binread(pdf.path)
    end

    private def build_envelope_definition(pdf_path:, subject:, signer:)
      document = DocuSign_eSign::Document.new(
        documentBase64: Base64.strict_encode64(File.binread(pdf_path)),
        name:           File.basename(pdf_path),
        fileExtension:  "pdf",
        documentId:     DOCUMENT_ID
      )

      DocuSign_eSign::EnvelopeDefinition.new(
        emailSubject: subject,
        documents:    [ document ],
        recipients:   DocuSign_eSign::Recipients.new(signers: [ build_signer(signer) ]),
        status:       "sent"
      )
    end

    private def build_signer(config)
      signer = DocuSign_eSign::Signer.new
      signer.email          = config.email
      signer.name           = config.name
      signer.recipient_id   = config.recipient_id.to_s
      signer.routing_order  = config.routing_order.to_s
      signer.client_user_id = config.client_user_id.to_s
      signer.tabs           = DocuSign_eSign::Tabs.new(textTabs: [ placeholder_tab(config) ])
      signer
    end

    # DocuSign refuses to complete an envelope whose signer has no tabs at all.
    # When the signature block lives in the PDF itself there is nothing natural to
    # attach, so a locked, non-required, empty text tab is parked here purely to
    # satisfy that constraint. The signer never interacts with it.
    private def placeholder_tab(config)
      DocuSign_eSign::Text.new(
        documentId:  DOCUMENT_ID,
        pageNumber:  "1",
        recipientId: config.recipient_id.to_s,
        xPosition:   "1",
        yPosition:   "1",
        value:       "",
        locked:      "true",
        required:    "false"
      )
    end
  end
end
