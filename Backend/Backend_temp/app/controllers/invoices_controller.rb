class InvoicesController < ApplicationController
  require 'nokogiri'
  require 'httparty'

  def upload_xml
    file = params[:file]
    return render json: { error: 'No file uploaded' }, status: :bad_request unless file

    doc = Nokogiri::XML(file.read)
    uuid = doc.at_xpath('//cfdi:Complemento//tfd:TimbreFiscalDigital',
      'cfdi' => 'http://www.sat.gob.mx/cfd/3', 'tfd' => 'http://www.sat.gob.mx/TimbreFiscalDigital')&.attr('UUID')
    customer = doc.at_xpath('//cfdi:Receptor', 'cfdi' => 'http://www.sat.gob.mx/cfd/3')&.attr('Nombre')
    issue_date = doc.at_xpath('//cfdi:Comprobante', 'cfdi' => 'http://www.sat.gob.mx/cfd/3')&.attr('Fecha')
    subtotal = doc.at_xpath('//cfdi:Comprobante', 'cfdi' => 'http://www.sat.gob.mx/cfd/3')&.attr('SubTotal')
    total = doc.at_xpath('//cfdi:Comprobante', 'cfdi' => 'http://www.sat.gob.mx/cfd/3')&.attr('Total')

    invoice = Invoice.create!(
      uuid: uuid,
      customer: customer,
      issue_date: issue_date,
      subtotal: subtotal,
      total: total
    )
    render json: invoice, status: :created
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def index
    invoices = Invoice.all.includes(:payment_complement)
    render json: invoices.as_json(include: :payment_complement)
  end

  def generate_payment_complement
    invoice = Invoice.find(params[:id])
    # Aquí se debe llamar a un job para timbrar usando Facturama
    # Simulación:
    job = PaymentComplementJob.perform_later(invoice.id)
    render json: { status: 'processing' }
  end
end
