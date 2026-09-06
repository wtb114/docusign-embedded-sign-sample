# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  around_action :switch_locale

  private def switch_locale(&action)
    I18n.with_locale(resolved_locale, &action)
  end

  # Precedence: an explicit ?locale= choice (remembered in the session),
  # then the browser's Accept-Language header, then the default locale.
  private def resolved_locale
    session[:locale] = params[:locale] if supported?(params[:locale])

    session[:locale] || locale_from_accept_language || I18n.default_locale
  end

  # Picks the first Accept-Language entry the app can actually render.
  # Quality values are ignored: browsers already send the list in preference order.
  private def locale_from_accept_language
    request.env["HTTP_ACCEPT_LANGUAGE"].to_s
      .scan(/[a-z]{2,3}(?:-[a-zA-Z]{2,4})?/)
      .map { |tag| tag.split("-").first }
      .find { |tag| supported?(tag) }
  end

  private def supported?(locale)
    locale.present? && I18n.available_locales.map(&:to_s).include?(locale.to_s)
  end
  helper_method :supported?
end
