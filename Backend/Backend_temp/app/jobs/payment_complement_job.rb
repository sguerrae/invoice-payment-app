class PaymentComplementJob < ApplicationJob
  queue_as :default

  def perform(invoice_id)
    invoice = Invoice.find(invoice_id)
    # Aquí va la lógica para llamar a Facturama y crear el complemento de pago
    # Simulación de respuesta:
    facturama_id = SecureRandom.uuid
    pdf_url = "https://sandbox.facturama.mx/api/v1/cfdi/#{facturama_id}/pdf"
    xml_url = "https://sandbox.facturama.mx/api/v1/cfdi/#{facturama_id}/xml"
    PaymentComplement.create!(
      invoice: invoice,
      facturama_id: facturama_id,
      pdf_url: pdf_url,
      xml_url: xml_url
    )
    invoice.update!(paid: true)
  end
end
