# frozen_string_literal: true

module Docusign
  # The boundary between the signing workflow and DocuSign itself.
  #
  # Two implementations sit behind it: ApiGateway talks to DocuSign, MockGateway
  # fakes it. SignService depends only on this interface and never touches the
  # DocuSign SDK, which is what lets the whole flow run without credentials.
  #
  # Implementations provide:
  #   create_embedded_signing(pdf_path:, subject:, signer:, return_url:) -> { envelope_id:, url: }
  #   recipient_view_url(envelope_id:, signer:, return_url:)             -> String
  #   completed?(envelope_id)                                            -> Boolean
  #   signed_pdf(envelope_id)                                            -> String (bytes)
  module Gateway
    def self.mock?
      ENV["DOCUSIGN_MOCK"] == "true"
    end

    def self.build
      mock? ? MockGateway.new : ApiGateway.new
    end
  end
end
