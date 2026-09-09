# frozen_string_literal: true

# One signature request, mapped one-to-one onto a DocuSign envelope.
#
# Status transitions:
#   issued  the envelope exists and is waiting for the signer
#   signed  signing finished and the signed PDF has been stored
#   revoked superseded, e.g. because the flow was restarted
#
# DocuSign-side identifiers carry an external_ prefix. Without it,
# document_id would collide with the foreign key to documents.
class Signature < ApplicationRecord
  belongs_to :document

  # The signed PDF pulled back from DocuSign, certificate page included.
  has_one_attached :file, dependent: :purge_later

  enum :status, { issued: 0, signed: 1, revoked: 2 }

  validates :external_envelope_id,  presence: true
  validates :external_recipient_id, presence: true
  validates :signed_at, presence: true, if: :signed?

  scope :active, -> { where(revoked_at: nil) }

  # Revoked either explicitly by status, or implicitly by carrying a revoked_at.
  # super is the predicate the enum generates.
  def revoked?
    super || revoked_at.present?
  end

  # Soft delete, so the history of signature requests stays auditable.
  def revoke!
    update!(status: :revoked, revoked_at: Time.current)
  end

  def default_filename
    "signed_document_#{document_id}_#{Time.current.strftime('%Y%m%d%H%M%S')}.pdf"
  end

  def complete!(pdf_bytes)
    transaction do
      file.attach(
        io: StringIO.new(pdf_bytes),
        filename: default_filename,
        content_type: "application/pdf"
      )
      update!(status: :signed, signed_at: Time.current)
    end
  end
end
