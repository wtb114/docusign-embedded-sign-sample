# frozen_string_literal: true

module Docusign
  # Stands in for DocuSign so the flow can run without credentials.
  #
  # Used when DOCUSIGN_MOCK=true. Instead of a DocuSign-hosted URL it returns an
  # in-app path, /mock_docusign/:envelope_id, which behaves the same way on the
  # way back: it redirects to return_url with event=signing_complete.
  #
  # The "signed" PDF is the uploaded file returned unchanged; there is no
  # certificate page.
  class MockGateway
    STORE_DIR = Rails.root.join("tmp", "mock_docusign")

    def create_embedded_signing(pdf_path:, subject:, signer:, return_url:)
      envelope_id = "MOCK-#{SecureRandom.uuid}"
      FileUtils.mkdir_p(STORE_DIR)
      FileUtils.cp(pdf_path, pdf_store_path(envelope_id))

      Rails.logger.info(
        "[DocuSign:mock] envelope created envelope_id=#{envelope_id} " \
        "subject=#{subject} signer=#{signer.email}"
      )

      { envelope_id: envelope_id, url: signing_url(envelope_id, return_url) }
    end

    def recipient_view_url(envelope_id:, signer:, return_url:)
      Rails.logger.info("[DocuSign:mock] signing URL reissued envelope_id=#{envelope_id} signer=#{signer.email}")
      signing_url(envelope_id, return_url)
    end

    def completed?(envelope_id)
      completion_marker_path(envelope_id).exist?
    end

    def signed_pdf(envelope_id)
      path = pdf_store_path(envelope_id)
      raise ApiError, I18n.t("docusign.errors.mock_pdf_missing", envelope_id: envelope_id) unless path.exist?

      path.binread
    end

    # Called when the mock signing screen's Sign button is pressed.
    def complete!(envelope_id)
      FileUtils.mkdir_p(STORE_DIR)
      FileUtils.touch(completion_marker_path(envelope_id))
    end

    private def signing_url(envelope_id, return_url)
      "/mock_docusign/#{envelope_id}?#{URI.encode_www_form(return_url: return_url)}"
    end

    private def pdf_store_path(envelope_id)
      STORE_DIR.join("#{envelope_id}.pdf")
    end

    private def completion_marker_path(envelope_id)
      STORE_DIR.join("#{envelope_id}.completed")
    end
  end
end
