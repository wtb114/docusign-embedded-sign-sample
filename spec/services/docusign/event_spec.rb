# frozen_string_literal: true

require "rails_helper"

RSpec.describe Docusign::Event do
  describe "#success?" do
    it "is true only for signing_complete" do
      expect(described_class.new("signing_complete")).to be_success
    end

    it "is false for every other event, including a missing one" do
      %w[cancel decline session_timeout viewing_complete].each do |event|
        expect(described_class.new(event)).not_to be_success
      end

      expect(described_class.new(nil)).not_to be_success
    end
  end

  describe "#failure_message" do
    it "explains a cancellation" do
      expect(described_class.new("cancel").failure_message)
        .to eq(I18n.t("docusign.events.cancel"))
    end

    it "falls back to a generic message that names the unknown event" do
      expect(described_class.new("something_new").failure_message).to include("something_new")
    end

    it "reports an absent event as unknown rather than blank" do
      expect(described_class.new(nil).failure_message).to include("unknown")
    end
  end
end
