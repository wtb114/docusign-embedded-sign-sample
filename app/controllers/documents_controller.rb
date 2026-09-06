# frozen_string_literal: true

# Entry point for uploading documents and driving the signing flow.
class DocumentsController < ApplicationController
  before_action :set_document, only: %i[show sign signed download]

  def index
    @documents = Document.order(created_at: :desc)
  end

  def new
    @document = Document.new
  end

  def create
    @document = Document.new(document_params)

    if @document.save
      redirect_to @document, notice: t("flash.document_created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @signature = @document.completed_signature || @document.pending_signature
  end

  # Starts the signing flow and hands the signer over to DocuSign.
  def sign
    url = Docusign::SignService.new(document: @document)
      .start_signing!(return_url: signed_document_url(@document))

    # DocuSign is hosted on another domain, so the redirect has to opt in.
    redirect_to url, allow_other_host: true
  rescue Docusign::Error => exception
    redirect_to @document, alert: exception.message
  end

  # Where DocuSign sends the signer back to (the envelope's return_url).
  #
  # The event parameter only says how the signing window closed. It travels
  # through the browser, so it cannot be trusted as proof of signing:
  # SignService re-checks the envelope status against the API before
  # storing anything.
  def signed
    event = Docusign::Event.new(params[:event])
    return redirect_to(@document, alert: event.failure_message) unless event.success?

    signature = Docusign::SignService.new(document: @document).finish_signing!

    if signature
      redirect_to @document, notice: t("flash.signing_completed")
    else
      redirect_to @document, alert: t("flash.not_completed_yet")
    end
  rescue Docusign::Error => exception
    redirect_to @document, alert: exception.message
  end

  def download
    signature = @document.completed_signature
    return redirect_to(@document, alert: t("flash.no_signed_pdf")) if signature.blank?

    redirect_to rails_blob_path(signature.file, disposition: "attachment")
  end

  private def set_document
    @document = Document.find(params[:id])
  end

  private def document_params
    params.expect(document: %i[title signer_name signer_email file])
  end
end
