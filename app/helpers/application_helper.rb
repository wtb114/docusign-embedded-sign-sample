# frozen_string_literal: true

module ApplicationHelper
  # Builds the current URL with ?locale= replaced.
  # Rebuilding from fullpath (rather than url_for) keeps every query parameter,
  # which matters on the mock signing screen where return_url lives in the query.
  def locale_url(locale)
    uri = URI.parse(request.fullpath)
    uri.query = Rack::Utils.parse_query(uri.query).merge("locale" => locale.to_s).to_query
    uri.to_s
  end

  # Endonyms: a language switcher shows each language in its own language,
  # so these labels are deliberately not translated.
  LOCALE_LABELS = { en: "EN", ja: "日本語" }.freeze

  def locale_label(locale)
    LOCALE_LABELS.fetch(locale.to_sym, locale.to_s.upcase)
  end

  # Maps a document to its status badge (CSS modifier + translated label).
  def document_status(document)
    if document.signed?
      [:signed, t("status.signed")]
    elsif document.pending_signature
      [:pending, t("status.pending")]
    else
      [:unsigned, t("status.unsigned")]
    end
  end

  def status_badge(document)
    modifier, label = document_status(document)
    tag.span(class: "badge #{modifier}") do
      tag.span(class: "dot") + label
    end
  end
end
