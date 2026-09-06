# frozen_string_literal: true

module Docusign
  # The event query parameter DocuSign appends to return_url.
  #
  # It only reports how the signing window closed. Because it arrives through the
  # browser, anyone can append it by hand, so it must never be treated as proof
  # that signing happened. Use it for messaging; confirm the outcome via the API.
  class Event
    module Types
      SIGNING_COMPLETE   = "signing_complete"
      ACCESS_CODE_FAILED = "access_code_failed"
      CANCEL             = "cancel"
      DECLINE            = "decline"
      EXCEPTION          = "exception"
      FAX_PENDING        = "fax_pending"
      ID_CHECK_FAILED    = "id_check_failed"
      SESSION_TIMEOUT    = "session_timeout"
      TTL_EXPIRED        = "ttl_expired"
      VIEWING_COMPLETE   = "viewing_complete"
    end

    attr_reader :value

    def initialize(value)
      @value = value.to_s
    end

    def success?
      value == Types::SIGNING_COMPLETE
    end

    def failure_message
      case value
      when Types::CANCEL
        I18n.t("docusign.events.cancel")
      when Types::DECLINE
        I18n.t("docusign.events.decline")
      when Types::SESSION_TIMEOUT, Types::TTL_EXPIRED
        I18n.t("docusign.events.timeout")
      when Types::ACCESS_CODE_FAILED, Types::ID_CHECK_FAILED
        I18n.t("docusign.events.identity_failed")
      else
        I18n.t("docusign.events.unknown", event: value.presence || "unknown")
      end
    end
  end
end
