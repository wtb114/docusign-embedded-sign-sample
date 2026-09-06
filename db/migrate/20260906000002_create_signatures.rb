# frozen_string_literal: true

class CreateSignatures < ActiveRecord::Migration[8.0]
  def change
    create_table :signatures do |t|
      t.references :document, null: false, foreign_key: true

      # DocuSign-side identifiers. The external_ prefix keeps external_document_id
      # from colliding with the document_id foreign key above.
      t.string :external_envelope_id,  null: false
      t.string :external_document_id,  null: false, default: "1"
      t.string :external_recipient_id, null: false, default: "1"

      # The DocuSign user impersonated when this envelope was created, so an
      # in-flight envelope can still be authenticated if the default user changes.
      t.string :docusign_user_id

      t.integer  :status, null: false, default: 0
      t.datetime :signed_at
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :signatures, :external_envelope_id
    add_index :signatures, %i[document_id status]
  end
end
