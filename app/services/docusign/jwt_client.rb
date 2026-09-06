# frozen_string_literal: true

module Docusign
  # Obtains DocuSign access tokens via the JWT Grant (impersonation) flow.
  #
  # Unlike the Authorization Code flow, no user signs in at request time: the
  # server acts as a specific DocuSign user. That user has to grant consent once,
  # by opening the consent URL in a browser (see docs/docusign-setup.md).
  #
  # Tokens live for at most one hour. Minting one per request runs into DocuSign
  # rate limits, so tokens are cached for 50 minutes.
  class JwtClient
    SCOPE         = "signature impersonation"
    TOKEN_TTL_SEC = 3600
    CACHE_TTL     = 50.minutes

    class << self
      def api_client(docusign_user_id:)
        client = DocuSign_eSign::ApiClient.new
        client.config.host      = api_host
        client.config.base_path = "/restapi"
        client.set_oauth_base_path(oauth_base_url)
        client.set_default_header("Authorization", "Bearer #{access_token(client, docusign_user_id)}")
        client
      end

      def account_id      = ENV.fetch("DOCUSIGN_ACCOUNT_ID")
      def integration_key = ENV.fetch("DOCUSIGN_INTEGRATION_KEY")
      def user_id         = ENV.fetch("DOCUSIGN_USER_ID")

      # Developer sandbox defaults. Production uses account.docusign.com
      # and https://www.docusign.net.
      def oauth_base_url = ENV.fetch("DOCUSIGN_OAUTH_BASE_URL", "account-d.docusign.com")
      def api_host       = ENV.fetch("DOCUSIGN_API_HOST", "https://demo.docusign.net")

      # One-time consent URL. Open it as the impersonated user and approve;
      # after that the server can mint tokens on its own.
      def consent_url(redirect_uri:)
        query = URI.encode_www_form(
          response_type: "code",
          scope:         SCOPE,
          client_id:     integration_key,
          redirect_uri:  redirect_uri
        )
        "https://#{oauth_base_url}/oauth/auth?#{query}"
      end

      private def access_token(client, docusign_user_id)
        Rails.cache.fetch("docusign:jwt:#{docusign_user_id}", expires_in: CACHE_TTL) do
          Rails.logger.info("[DocuSign] requesting a new JWT access token user_id=#{docusign_user_id}")
          client.request_jwt_user_token(
            integration_key,
            docusign_user_id,
            private_key,
            TOKEN_TTL_SEC,
            SCOPE
          ).access_token
        end
      end

      # The RSA key contains newlines, so it is passed in Base64-encoded:
      #   base64 -w0 private.key
      private def private_key
        Base64.decode64(ENV.fetch("DOCUSIGN_PRIVATE_KEY_BASE64"))
      end
    end
  end
end
