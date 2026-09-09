# frozen_string_literal: true

module Docusign
  # The stored state does not match what the flow expects: already signed,
  # no pending signature record, and so on.
  class InconsistentStateError < Error; end
end
