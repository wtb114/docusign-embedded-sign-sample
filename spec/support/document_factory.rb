# frozen_string_literal: true

# Minimal factory helpers. The suite is small enough that a couple of methods
# beat pulling in a factory library.
module DocumentFactory
  SAMPLE_PDF = Rails.root.join("sample_files/service-agreement.pdf")

  def build_document(**attributes)
    Document.new(
      {
        title: "Service Agreement",
        signer_name: "Jane Doe",
        signer_email: "jane.doe@example.com"
      }.merge(attributes)
    )
  end

  def attach_sample_pdf(document, content_type: "application/pdf")
    document.file.attach(
      io: File.open(SAMPLE_PDF),
      filename: "service-agreement.pdf",
      content_type: content_type,
      # Without this Active Storage re-detects the type from the bytes,
      # which would defeat the "not a PDF" case.
      identify: false
    )
    document
  end

  def create_document(**attributes)
    document = build_document(**attributes)
    attach_sample_pdf(document)
    document.save!
    document
  end
end
