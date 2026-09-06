# frozen_string_literal: true

# A document to be signed.
#
# One document has exactly one signer. Starting the flow creates a Signature,
# which maps one-to-one onto a DocuSign envelope.
class Document < ApplicationRecord
  has_one_attached :file, dependent: :purge_later
  has_many :signatures, dependent: :destroy

  validates :title, presence: true
  validates :signer_name, presence: true
  validates :signer_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate  :file_must_be_pdf

  def signed?
    signatures.active.signed.exists?
  end

  # The signature request that is waiting for the signer to finish.
  def pending_signature
    signatures.active.issued.order(created_at: :desc).first
  end

  def completed_signature
    signatures.active.signed.order(Arel.sql("COALESCE(signed_at, created_at) DESC")).first
  end

  # Invalidates any in-flight signature request so the flow can be restarted.
  # DocuSign signing URLs expire after a few minutes, so a signer who walks
  # away needs a fresh envelope rather than a stale link.
  def revoke_pending_signatures!
    signatures.active.issued.find_each(&:revoke!)
  end

  private def file_must_be_pdf
    return unless file.attached?

    errors.add(:file, :not_pdf) unless file.content_type == "application/pdf"
  end
end
