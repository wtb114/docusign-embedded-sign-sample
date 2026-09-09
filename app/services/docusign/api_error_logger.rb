# frozen_string_literal: true

module Docusign
  # Writes DocuSign API failures out as structured JSON.
  #
  # x-docusign-trace-token is the one field DocuSign support asks for, so it is
  # pulled out of the response headers and always logged.
  module ApiErrorLogger
    RESPONSE_BODY_LIMIT = 1_000

    def self.log(exception, document: nil, signature: nil)
      Rails.logger.error({
        type:          "DocuSignApiError",
        code:          exception.try(:code),
        message:       exception.message,
        trace_token:   exception.try(:response_headers)&.dig("x-docusign-trace-token"),
        response_body: exception.try(:response_body).to_s[0, RESPONSE_BODY_LIMIT],
        document_id:   document&.id,
        signature_id:  signature&.id,
        envelope_id:   signature&.external_envelope_id
      }.to_json)
    end
  end
end
