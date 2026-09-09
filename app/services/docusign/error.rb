# frozen_string_literal: true

module Docusign
  # Base class for errors the UI is expected to show to the user.
  #
  # Zeitwerk maps one constant per file, so each subclass lives in its own file
  # rather than being grouped here.
  class Error < StandardError; end
end
