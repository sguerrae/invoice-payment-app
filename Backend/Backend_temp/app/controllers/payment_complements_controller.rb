class PaymentComplementsController < ApplicationController
  def download
    payment_complement = PaymentComplement.find(params[:id])
    # Aquí deberías descargar el PDF y XML desde Facturama usando las URLs guardadas
    render json: {
      pdf_url: payment_complement.pdf_url,
      xml_url: payment_complement.xml_url
    }
  end
end
