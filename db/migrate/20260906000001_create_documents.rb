# frozen_string_literal: true

class CreateDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :documents do |t|
      t.string :title,        null: false
      t.string :signer_name,  null: false
      t.string :signer_email, null: false

      t.timestamps
    end
  end
end
