# frozen_string_literal: true

# English is the default so that visitors without a matching Accept-Language
# header land on the English UI. ApplicationController narrows this down per
# request from the session or the browser's Accept-Language header.
Rails.application.config.i18n.default_locale = :en
Rails.application.config.i18n.available_locales = %i[en ja]
