# frozen_string_literal: true

module Docusign
  # Everything needed to describe one signer to DocuSign.
  #
  # Setting client_user_id is what turns the envelope into an *embedded* signing
  # session. Leave it out and DocuSign emails the signer instead, which takes the
  # flow out of the application entirely.
  SignerConfig = Struct.new(
    :name,
    :email,
    :recipient_id,
    :routing_order,
    :client_user_id,
    keyword_init: true
  )
end
