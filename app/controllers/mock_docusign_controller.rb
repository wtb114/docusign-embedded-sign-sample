# frozen_string_literal: true

# Stands in for the DocuSign hosted signing session while DOCUSIGN_MOCK=true.
#
# It mirrors what the real signing session does on the way out: signing returns
# to return_url with event=signing_complete, cancelling returns with event=cancel.
# That keeps the rest of the application on the exact same code path as production.
class MockDocusignController < ApplicationController
  before_action :ensure_mock_mode

  def show
    @envelope_id = params[:envelope_id]
    @return_url  = params[:return_url]
    @cancel_url  = url_with_event(@return_url, Docusign::Event::Types::CANCEL)
  end

  def complete
    Docusign::MockGateway.new.complete!(params[:envelope_id])

    # No allow_other_host here: return_url arrives as a request parameter, and
    # this stand-in must not become an open redirect. Rails refuses anything
    # that is not on this host, which is all the mock ever needs.
    redirect_to url_with_event(params[:return_url], Docusign::Event::Types::SIGNING_COMPLETE)
  end

  private def url_with_event(return_url, event)
    uri = URI.parse(return_url)
    uri.query = Rack::Utils.parse_query(uri.query).merge("event" => event).to_query
    uri.to_s
  end

  private def ensure_mock_mode
    head :not_found unless Docusign::Gateway.mock?
  end
end
