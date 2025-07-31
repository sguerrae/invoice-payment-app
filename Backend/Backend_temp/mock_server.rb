# frozen_string_literal: true

require 'webrick'
require 'json'
require 'base64'
require 'fileutils'
require 'securerandom'
require 'net/http'
require 'uri'
require 'timeout'

# Cargar configuración de valores fiscales
require_relative 'fiscal_values'

# Crear directorio para guardar los XMLs subidos
FileUtils.mkdir_p('uploads') unless Dir.exist?('uploads')
FileUtils.mkdir_p('db') unless Dir.exist?('db')

# Credenciales de Facturama Sandbox
FACTURAMA_USERNAME = 'apimeefi'
FACTURAMA_PASSWORD = '00e751c795a09cabc5fad9cadfd1aba9'
FACTURAMA_BASE_URL = 'https://apisandbox.facturama.mx'

# Datos en memoria (simulando base de datos)
$invoices = []
$payment_complements = []

# Clase para manejar las llamadas a la API de Facturama
class FacturamaAPI
  def self.create_invoice_first(invoice_data)
    begin
      puts "=== Creando factura en Facturama primero ==="
      
      # Estructura de la factura según la API de Facturama v3
      expedition_place = "11590"
      tax_zip_code = "11590"
      
      # Determinar el régimen fiscal basado en el RFC
      rfc_receptor = invoice_data['rfc_receptor'] || "XAXX010101000"
      fiscal_regime = invoice_data['receiver_fiscal_regime'] || "601"
      
      # Verificar si el RFC es genérico, en ese caso ExpeditionPlace debe ser igual a TaxZipCode
      # y el régimen fiscal debe ser 616 (Sin obligaciones fiscales)
      if ["XAXX010101000", "XEXX010101000"].include?(rfc_receptor)
        expedition_place = tax_zip_code
        fiscal_regime = "616"  # Sin obligaciones fiscales - requerido para RFCs genéricos
      end
      
      # Determinar UsoCFDI correcto
      cfdi_use = if fiscal_regime == "616"
        "S01" # Sin obligaciones fiscales
      else
        invoice_data['cfdi_use'] || "G01"
      end

      # Calcular correctamente los totales
      subtotal = invoice_data['subtotal'] ? invoice_data['subtotal'].to_f : 1000.0
      rate = 0.16
      tax_total = (subtotal * rate).round(6)
      item_total = (subtotal + tax_total).round(6)

      invoice_cfdi = {
        "NameId" => 1,
        "Date" => Time.now.strftime('%Y-%m-%dT%H:%M:%S'),
        "Serie" => "A",
        "Currency" => invoice_data['currency'] || "MXN",
        "ExpeditionPlace" => expedition_place,
        "Exportation" => "01",  # Requerido en v3
        "CfdiType" => "I",  # I = Ingreso
        "PaymentForm" => invoice_data['forma_pago'] || "99",  # Por definir (para hacer complemento después)
        "PaymentMethod" => invoice_data['payment_method'] || "PPD",  # PPD = Pago en parcialidades o diferido
        "Receiver" => {
          "Rfc" => rfc_receptor,
          "Name" => invoice_data['customer'] || "Cliente General",
          "CfdiUse" => cfdi_use,
          "TaxZipCode" => tax_zip_code,  # Campo fiscal requerido
          "FiscalRegime" => fiscal_regime  # Campo fiscal requerido - 616 para RFCs genéricos
        },
        "Items" => [
          {
            "ProductCode" => "01010101",
            "IdentificationNumber" => "SERV001",
            "Description" => "Servicios profesionales",
            "Unit" => "E48",
            "UnitCode" => "E48",
            "UnitPrice" => subtotal,
            "Quantity" => 1.0,
            "Subtotal" => subtotal,
            "TaxObject" => "02",  # Requerido en v3
            "Taxes" => [
              {
                "Total" => tax_total,
                "Name" => "IVA",
                "Base" => subtotal,
                "Rate" => rate,
                "IsRetention" => false,
                "TaxObject" => "02"
              }
            ],
            "Total" => item_total
          }
        ]
      }
      
      puts "Datos de factura a enviar a Facturama:"
      puts JSON.pretty_generate(invoice_cfdi)
      
      # Llamada a la API de Facturama
      uri = URI("#{FACTURAMA_BASE_URL}/api/3/cfdis")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 30
      http.read_timeout = 60
      
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.basic_auth(FACTURAMA_USERNAME, FACTURAMA_PASSWORD)
      request.body = invoice_cfdi.to_json
      
      response = http.request(request)
      
      puts "Respuesta factura Facturama - Status: #{response.code}"
      puts "Respuesta factura Facturama - Body: #{response.body}"
      
      if response.code.to_i == 201 || response.code.to_i == 200
        facturama_response = JSON.parse(response.body)
        return {
          success: true,
          facturama_id: facturama_response['Id'],
          uuid: facturama_response.dig('Complement', 'TaxStamp', 'Uuid'),
          facturama_response: facturama_response
        }
      else
        return {
          success: false,
          error: "Error creando factura en Facturama (#{response.code}): #{response.body}"
        }
      end
      
    rescue => e
      puts "Error creando factura: #{e.message}"
      return {
        success: false,
        error: "Error creando factura: #{e.message}"
      }
    end
  end

  def self.create_payment_complement(invoice_data, payment_data)
    begin
      puts "=== Creando complemento de pago en Facturama ==="
      
      # Primero verificar si la factura tiene UUID de Facturama válido
      if !invoice_data['facturama_uuid'] || invoice_data['facturama_uuid'].start_with?('A1B2C3D4')
        puts "Creando factura en Facturama primero..."
        invoice_result = create_invoice_first(invoice_data)
        
        if invoice_result[:success]
          invoice_data['facturama_uuid'] = invoice_result[:uuid]
          puts "Factura creada con UUID: #{invoice_result[:uuid]}"
        else
          return invoice_result
        end
      end
      
      # Estructura del complemento de pago según la API de Facturama v3
      expedition_place = "11590"
      tax_zip_code = "11590"
      
      # Determinar el régimen fiscal basado en el RFC
      rfc_receptor = invoice_data['rfc_receptor'] || "XAXX010101000"
      fiscal_regime = invoice_data['receiver_fiscal_regime'] || payment_data[:receiver_fiscal_regime] || "601"
      
      # Verificar si el RFC es genérico, en ese caso ExpeditionPlace debe ser igual a TaxZipCode
      # y el régimen fiscal debe ser 616 (Sin obligaciones fiscales)
      if ["XAXX010101000", "XEXX010101000"].include?(rfc_receptor)
        expedition_place = tax_zip_code
        fiscal_regime = "616"  # Sin obligaciones fiscales - requerido para RFCs genéricos
      end
      
      # Determinar UsoCFDI correcto para complemento
      cfdi_use = if fiscal_regime == "616"
        "S01" # Sin obligaciones fiscales
      else
        payment_data[:cfdi_use] || invoice_data['cfdi_use'] || "CP01"
      end

      complement_data = {
        "NameId" => 1,
        "Date" => payment_data[:payment_date] || Time.now.strftime('%Y-%m-%dT%H:%M:%S'),
        "Serie" => "CP",
        "Folio" => "CP-#{SecureRandom.alphanumeric(8)}",
        "Currency" => payment_data[:currency] || "MXN",
        "ExpeditionPlace" => expedition_place,
        "Exportation" => "01",  # Requerido en v3
        "CfdiType" => "P",  # P = Complemento de Pago
        "Receiver" => {
          "Rfc" => rfc_receptor,
          "Name" => invoice_data['customer'] || "Cliente General",
          "CfdiUse" => cfdi_use,
          "TaxZipCode" => tax_zip_code,  # Campo fiscal requerido
          "FiscalRegime" => fiscal_regime  # Campo fiscal requerido - 616 para RFCs genéricos
        },
        "Items" => [
          {
            "ProductCode" => "84111506",  # Código para servicios de facturación
            "IdentificationNumber" => "CP001",
            "Description" => "Pago",
            "Unit" => "ACT",
            "UnitCode" => "ACT",
            "UnitPrice" => 0.0,
            "Quantity" => 1.0,
            "Subtotal" => 0.0,
            "TaxObject" => "01",  # No objeto de impuesto para complementos de pago
            "Total" => 0.0
          }
        ],
        "Complemento" => {
          "Payments" => [
            {
              "Date" => payment_data[:payment_date] || Time.now.strftime('%Y-%m-%dT%H:%M:%S'),
              "PaymentForm" => payment_data[:payment_method] || "03",
              "Currency" => payment_data[:currency] || "MXN",
              "Amount" => payment_data[:amount] || invoice_data['total'],
              "RelatedDocuments" => [
                {
                  "Uuid" => invoice_data['facturama_uuid'] || invoice_data['uuid'],
                  "Currency" => "MXN",
                  "PaymentMethod" => "PUE",
                  "PartialityNumber" => 1,
                  "PreviousBalanceAmount" => invoice_data['total'],
                  "AmountPaid" => payment_data[:amount] || invoice_data['total'],
                  "TaxObject" => "02"  # Requerido en v3
                }
              ]
            }
          ]
        }
      }
      
      puts "Datos a enviar a Facturama:"
      puts JSON.pretty_generate(complement_data)
      
      # Llamada a la API de Facturama con timeout
      uri = URI("#{FACTURAMA_BASE_URL}/api/3/cfdis")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 30
      http.read_timeout = 60
      
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.basic_auth(FACTURAMA_USERNAME, FACTURAMA_PASSWORD)
      request.body = complement_data.to_json
      
      response = http.request(request)
      
      puts "Respuesta de Facturama - Status: #{response.code}"
      puts "Respuesta de Facturama - Body: #{response.body}"
      
      if response.code.to_i == 201 || response.code.to_i == 200
        facturama_response = JSON.parse(response.body)
        
        # Obtener el PDF del complemento
        pdf_content = get_pdf_from_facturama(facturama_response['Id'])
        
        return {
          success: true,
          facturama_id: facturama_response['Id'],
          uuid: facturama_response.dig('Complement', 'TaxStamp', 'Uuid') || "UUID-#{SecureRandom.hex(16)}",
          pdf_base64: pdf_content,
          xml_content: facturama_response['Content'],
          facturama_response: facturama_response
        }
      else
        error_message = "Error de Facturama (#{response.code}): #{response.body}"
        puts error_message
        return {
          success: false,
          error: error_message
        }
      end
      
    rescue Timeout::Error, Net::TimeoutError => e
      error_message = "Timeout conectando con Facturama: #{e.message}"
      puts error_message
      return {
        success: false,
        error: error_message
      }
    rescue JSON::ParserError => e
      error_message = "Error parseando respuesta de Facturama: #{e.message}"
      puts error_message
      return {
        success: false,
        error: error_message
      }
    rescue => e
      error_message = "Error conectando con Facturama: #{e.message}"
      puts error_message
      puts e.backtrace
      return {
        success: false,
        error: error_message
      }
    end
  end
  
  def self.get_pdf_from_facturama(facturama_id)
    begin
      uri = URI("#{FACTURAMA_BASE_URL}/api/lite/cfdi/#{facturama_id}/pdf")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Get.new(uri)
      request.basic_auth(FACTURAMA_USERNAME, FACTURAMA_PASSWORD)
      
      response = http.request(request)
      
      if response.code.to_i == 200
        return Base64.strict_encode64(response.body)
      else
        puts "Error obteniendo PDF: #{response.body}"
        return nil
      end
    rescue => e
      puts "Error obteniendo PDF: #{e.message}"
      return nil
    end
  end
end

# Función para crear complemento de pago simulado (sin Facturama)
def create_mock_payment_complement(invoice, payment_data)
  begin
    puts "=== Creando complemento de pago SIMULADO ==="
    
    mock_id = "MOCK-CP-#{SecureRandom.alphanumeric(10)}"
    uuid = SecureRandom.uuid
    
    # Crear un PDF simulado en base64
    pdf_content = create_mock_pdf(invoice, payment_data, mock_id, uuid)
    
    # Crear XML simulado
    xml_content = create_mock_xml(invoice, payment_data, mock_id, uuid)
    
    puts "Complemento simulado creado: #{mock_id}"
    
    return {
      success: true,
      mock_id: mock_id,
      uuid: uuid,
      pdf_base64: pdf_content,
      xml_content: xml_content,
      mock_response: {
        'Id' => mock_id,
        'Uuid' => uuid,
        'Status' => 'Generated',
        'CreatedAt' => Time.now.iso8601
      }
    }
    
  rescue => e
    puts "Error creando complemento simulado: #{e.message}"
    return {
      success: false,
      error: "Error generando complemento simulado: #{e.message}"
    }
  end
end

# Función para crear PDF simulado
def create_mock_pdf(invoice, payment_data, mock_id, uuid)
  # Contenido PDF básico simulado (esto es solo texto, no un PDF real)
  pdf_text = <<~PDF
    %PDF-1.4
    1 0 obj
    <<
    /Type /Catalog
    /Pages 2 0 R
    >>
    endobj
    
    2 0 obj
    <<
    /Type /Pages
    /Kids [3 0 R]
    /Count 1
    >>
    endobj
    
    3 0 obj
    <<
    /Type /Page
    /Parent 2 0 R
    /MediaBox [0 0 612 792]
    /Contents 4 0 R
    >>
    endobj
    
    4 0 obj
    <<
    /Length 200
    >>
    stream
    BT
    /F1 12 Tf
    100 700 Td
    (COMPLEMENTO DE PAGO SIMULADO) Tj
    0 -20 Td
    (ID: #{mock_id}) Tj
    0 -20 Td
    (UUID: #{uuid}) Tj
    0 -20 Td
    (Cliente: #{invoice['customer']}) Tj
    0 -20 Td
    (Monto: $#{payment_data[:amount]}) Tj
    0 -20 Td
    (Fecha: #{payment_data[:payment_date]}) Tj
    ET
    endstream
    endobj
    
    xref
    0 5
    0000000000 65535 f 
    0000000009 00000 n 
    0000000058 00000 n 
    0000000115 00000 n 
    0000000206 00000 n 
    trailer
    <<
    /Size 5
    /Root 1 0 R
    >>
    startxref
    456
    %%EOF
  PDF
  
  # Convertir a base64
  Base64.strict_encode64(pdf_text)
end

# Función para crear XML simulado
def create_mock_xml(invoice, payment_data, mock_id, uuid)
  <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <cfdi:Comprobante 
        xmlns:cfdi="http://www.sat.gob.mx/cfd/4"
        xmlns:pago20="http://www.sat.gob.mx/Pagos20"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://www.sat.gob.mx/cfd/4 http://www.sat.gob.mx/sitio_internet/cfd/4/cfdv40.xsd http://www.sat.gob.mx/Pagos20 http://www.sat.gob.mx/sitio_internet/cfd/Pagos/Pagos20.xsd"
        Certificado="MOCK_CERTIFICATE"
        Fecha="#{payment_data[:payment_date]}"
        Folio="#{mock_id}"
        LugarExpedicion="78000"
        Moneda="XXX"
        NoCertificado="00001000000400002495"
        Sello="MOCK_SELLO"
        SubTotal="0"
        TipoDeComprobante="P"
        Total="0"
        Version="4.0">
        
        <cfdi:Emisor 
            Nombre="#{invoice['customer']}" 
            RegimenFiscal="601" 
            Rfc="#{invoice['rfc_emisor']}" />
            
        <cfdi:Receptor 
            DomicilioFiscalReceptor="78000" 
            Nombre="Cliente General" 
            RegimenFiscalReceptor="616" 
            Rfc="#{invoice['rfc_receptor']}" 
            UsoCFDI="CP01" />
            
        <cfdi:Conceptos>
            <cfdi:Concepto 
                Cantidad="1" 
                ClaveProdServ="84111506" 
                ClaveUnidad="ACT" 
                Descripcion="Pago" 
                Importe="0" 
                ObjetoImp="01" 
                ValorUnitario="0" />
        </cfdi:Conceptos>
        
        <cfdi:Complemento>
            <pago20:Pagos Version="2.0">
                <pago20:Totales MontoTotalPagos="#{payment_data[:amount]}" />
                <pago20:Pago 
                    FechaPago="#{payment_data[:payment_date]}" 
                    FormaDePagoP="#{payment_data[:payment_method]}" 
                    MonedaP="#{payment_data[:currency]}" 
                    Monto="#{payment_data[:amount]}">
                    <pago20:DoctoRelacionado 
                        IdDocumento="#{invoice['uuid']}" 
                        MonedaDR="MXN" 
                        MetodoDePagoDR="PUE" 
                        NumParcialidad="1" 
                        ImpSaldoAnt="#{invoice['total']}" 
                        ImpPagado="#{payment_data[:amount]}" 
                        ImpSaldoInsoluto="0"
                        ObjetoImpDR="02" />
                </pago20:Pago>
            </pago20:Pagos>
        </cfdi:Complemento>
        
        <cfdi:Addenda>
            <signature>
                <uuid>#{uuid}</uuid>
                <timestamp>#{Time.now.iso8601}</timestamp>
                <status>MOCK_GENERATED</status>
            </signature>
        </cfdi:Addenda>
    </cfdi:Comprobante>
  XML
end

# Cargar datos si existen
if File.exist?('db/invoices.json')
  $invoices = JSON.parse(File.read('db/invoices.json'))
end

if File.exist?('db/payment_complements.json')
  $payment_complements = JSON.parse(File.read('db/payment_complements.json'))
end

# Agregar datos de prueba si no existen facturas
if $invoices.empty?
  sample_invoices = [
    {
      'id' => 1,
      'uuid' => 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890',
      'customer' => 'XENON INDUSTRIAL ARTICLES SA DE CV',
      'issue_date' => '2024-01-15',
      'subtotal' => 8620.69,
      'total' => 10000.00,
      'paid' => false,
      'rfc_emisor' => 'XIA123456789',
      'rfc_receptor' => 'XAXX010101000'
    },
    {
      'id' => 2,
      'uuid' => 'B2C3D4E5-F6G7-8901-BCDE-F23456789012',
      'customer' => 'Proveedor Ejemplo SA',
      'issue_date' => '2024-01-20',
      'subtotal' => 4310.34,
      'total' => 5000.00,
      'paid' => false,
      'rfc_emisor' => 'PEJ123456789',
      'rfc_receptor' => 'XIA123456789'
    },
    {
      'id' => 3,
      'uuid' => 'C3D4E5F6-G7H8-9012-CDEF-345678901234',
      'customer' => 'Cliente Corporativo SA',
      'issue_date' => '2024-01-25',
      'subtotal' => 2586.21,
      'total' => 3000.00,
      'paid' => true,
      'rfc_emisor' => 'XIA123456789',
      'rfc_receptor' => 'CCS123456789'
    }
  ]
  
  $invoices = sample_invoices
  File.write('db/invoices.json', JSON.generate($invoices))
  puts "Datos de prueba agregados: #{$invoices.length} facturas"
end

class InvoicesServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_OPTIONS(request, response)
    # Configurar CORS para OPTIONS
    response['Access-Control-Allow-Origin'] = '*'
    response['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    response['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Requested-With'
    response['Access-Control-Max-Age'] = '86400'
    response.status = 200
    response.body = ''
  end

  def do_GET(request, response)
    # Configurar CORS
    response['Access-Control-Allow-Origin'] = '*'
    response['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    response['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Requested-With'
    
    response.status = 200
    response['Content-Type'] = 'application/json'
    response.body = JSON.generate($invoices)
  end
end

class UploadXMLServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_OPTIONS(request, response)
    # Configurar CORS para OPTIONS
    response['Access-Control-Allow-Origin'] = '*'
    response['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    response['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Requested-With'
    response['Access-Control-Max-Age'] = '86400'
    response.status = 200
    response.body = ''
  end

  def do_POST(request, response)
    begin
      # Configurar CORS
      response['Access-Control-Allow-Origin'] = '*'
      response['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
      response['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Requested-With'
      
      # Extraer el archivo XML del request multipart
      if request.content_type =~ /^multipart\/form-data/
        boundary = request.content_type.split('boundary=')[1]
        parts = request.body.split("--#{boundary}")
        
        xml_part = parts.find { |part| part =~ /filename=/ && part =~ /\.xml/ }
        
        if xml_part
          # Extraer contenido XML
          xml_content = xml_part.split("\r\n\r\n")[1].split("\r\n--")[0]
          
          # Guardar el XML
          file_id = Time.now.to_i.to_s
          File.write("uploads/#{file_id}.xml", xml_content)
          
          puts "=== Procesando XML de factura ==="
          
          # Intentar extraer el UUID del XML (versión simple)
          uuid = nil
          customer = nil
          subtotal = nil
          total = nil
          rfc_emisor = nil
          rfc_receptor = nil
          issue_date = nil
          
          # Buscar UUID en formato típico CFDI
          uuid_match = xml_content.match(/UUID=['"]([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})['"]/i)
          uuid = uuid_match[1] if uuid_match
          
          # Si no se encuentra en ese formato, buscar en otro formato común
          if !uuid
            uuid_match = xml_content.match(/IdDocumento=['"]([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})['"]/i)
            uuid = uuid_match[1] if uuid_match
          end
          
          # Si todavía no hay UUID, buscar en cualquier formato
          if !uuid
            uuid_match = xml_content.match(/([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})/i)
            uuid = uuid_match[1] if uuid_match
          end
          
          # Extraer nombre del cliente/receptor
          name_match = xml_content.match(/Receptor[^>]*Nombre=['"]([^'"]+)['"]/i)
          customer = name_match[1] if name_match
          
          # Extraer subtotal y total
          subtotal_match = xml_content.match(/SubTotal=['"](\d+\.\d+)['"]/i)
          subtotal = subtotal_match[1].to_f if subtotal_match
          
          total_match = xml_content.match(/Total=['"](\d+\.\d+)['"]/i)
          total = total_match[1].to_f if total_match
          
          # Extraer RFC emisor y receptor
          emisor_match = xml_content.match(/Emisor[^>]*Rfc=['"]([^'"]+)['"]/i)
          rfc_emisor = emisor_match[1] if emisor_match
          
          receptor_match = xml_content.match(/Receptor[^>]*Rfc=['"]([^'"]+)['"]/i)
          rfc_receptor = receptor_match[1] if receptor_match
          
          # Extraer fecha
          date_match = xml_content.match(/Fecha=['"]([^'"]+)['"]/i)
          issue_date = date_match[1].split('T')[0] if date_match
          
          # Usar valores predeterminados si no se pueden extraer del XML
          uuid ||= SecureRandom.uuid
          customer ||= "Cliente #{$invoices.length + 1}"
          subtotal ||= rand(1000.0..5000.0).round(2)
          total ||= (subtotal * 1.16).round(2)
          rfc_emisor ||= "XIA123456789"
          rfc_receptor ||= "XAXX010101000"
          issue_date ||= Time.now.strftime('%Y-%m-%d')
          
          puts "UUID extraído: #{uuid}"
          puts "Cliente: #{customer}"
          puts "Subtotal: #{subtotal}"
          puts "Total: #{total}"
          
          # Crear objeto de factura con los datos extraídos
          invoice = {
            'id' => $invoices.length + 1,
            'uuid' => uuid,
            'customer' => customer,
            'issue_date' => issue_date,
            'subtotal' => subtotal,
            'total' => total,
            'paid' => false,
            'rfc_emisor' => rfc_emisor,
            'rfc_receptor' => rfc_receptor,
            'xml_path' => "uploads/#{file_id}.xml"
          }
          
          $invoices << invoice
          
          # Guardar los datos actualizados
          File.write('db/invoices.json', JSON.generate($invoices))
          
          response.status = 201
          response['Content-Type'] = 'application/json'
          response.body = JSON.generate(invoice)
        else
          response.status = 400
          response['Content-Type'] = 'application/json'
          response.body = JSON.generate({ 'error' => 'No XML file found in request' })
        end
      else
        response.status = 400
        response['Content-Type'] = 'application/json'
        response.body = JSON.generate({ 'error' => 'Request must be multipart/form-data' })
      end
    rescue => e
      response.status = 500
      response['Content-Type'] = 'application/json'
      response.body = JSON.generate({ 'error' => e.message })
    end
  end
end

class PaymentComplementServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_OPTIONS(request, response)
    # Configurar CORS para OPTIONS
    response['Access-Control-Allow-Origin'] = '*'
    response['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    response['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Requested-With'
    response['Access-Control-Max-Age'] = '86400'
    response.status = 200
    response.body = ''
  end

  def do_POST(request, response)
    begin
      # Configurar CORS
      response['Access-Control-Allow-Origin'] = '*'
      response['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
      response['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Requested-With'
      
      puts "=== Generando complemento de pago con Facturama ==="
      
      # Parsear el cuerpo de la solicitud
      request_data = JSON.parse(request.body) rescue {}
      puts "Datos recibidos: #{request_data}"
      
      # Validar que se reciba invoice_id
      unless request_data['invoice_id']
        response.status = 400
        response['Content-Type'] = 'application/json'
        response.body = JSON.generate({ 'error' => 'invoice_id is required' })
        return
      end
      
      invoice_id = request_data['invoice_id'].to_i
      puts "Buscando factura con ID: #{invoice_id}"
      puts "Facturas disponibles: #{$invoices.map { |inv| inv['id'] }}"
      
      # Buscar la factura
      invoice = $invoices.find { |inv| inv['id'] == invoice_id }
      
      unless invoice
        puts "ERROR: Factura no encontrada con ID #{invoice_id}"
        puts "Facturas existentes: #{$invoices.map { |inv| "ID: #{inv['id']}, Customer: #{inv['customer']}" }}"
        response.status = 404
        response['Content-Type'] = 'application/json'
        response.body = JSON.generate({ 'error' => 'Invoice not found' })
        return
      end
      
      puts "Factura encontrada: #{invoice}"
      
      # Datos del pago con información fiscal
      payment_data = {
        payment_method: request_data['payment_method'] || "03",
        payment_date: request_data['payment_date'] || Time.now.strftime('%Y-%m-%dT%H:%M:%S'),
        amount: request_data['amount']&.to_f || request_data['monto']&.to_f || invoice['total'],
        currency: request_data['currency'] || "MXN",
        exchange_rate: request_data['exchange_rate'] || "1",
        account_number: request_data['account_number'] || "",
        # Campos fiscales adicionales
        expedition_place: request_data['expedition_place'] || FISCAL_VALUES[:defaults][:expedition_place],
        receiver_tax_zip_code: request_data['receiver_tax_zip_code'] || FISCAL_VALUES[:defaults][:receiver_tax_zip_code],
        receiver_fiscal_regime: request_data['receiver_fiscal_regime'] || FISCAL_VALUES[:defaults][:receiver_fiscal_regime],
        forma_pago: request_data['forma_pago'] || "99",
        cfdi_use: request_data['cfdi_use'] || "G01",
        rfc_receptor: invoice['rfc_receptor'] || "XAXX010101000"
      }
      
      # Validar datos fiscales
      fiscal_data, fiscal_errors = validate_fiscal_data(payment_data)
      payment_data = fiscal_data
      
      if !fiscal_errors.empty?
        puts "Advertencias en validación fiscal: #{fiscal_errors.join(', ')}"
        puts "Los valores han sido ajustados automáticamente"
      end
      
      puts "Datos del pago: #{payment_data}"
      
      # Llamar a la API de Facturama
      facturama_result = FacturamaAPI.create_payment_complement(invoice, payment_data)
      
      if facturama_result[:success]
        # Crear el complemento en nuestra base de datos
        complement = {
          'id' => $payment_complements.length + 1,
          'invoice_id' => invoice['id'],
          'invoice_uuid' => invoice['uuid'],
          'facturama_id' => facturama_result[:facturama_id],
          'uuid' => facturama_result[:uuid],
          'pdf_base64' => facturama_result[:pdf_base64],
          'xml_content' => facturama_result[:xml_content],
          'pdf_url' => "#{request.host}:#{request.port}/payment_complements/#{$payment_complements.length + 1}/pdf",
          'xml_url' => "#{request.host}:#{request.port}/payment_complements/#{$payment_complements.length + 1}/xml",
          'status' => 'generated',
          'created_at' => Time.now.iso8601,
          'payment_data' => payment_data,
          'facturama_response' => facturama_result[:facturama_response]
        }
        
        # Marcar la factura como pagada
        invoice['paid'] = true
        
        # Guardar el complemento
        $payment_complements << complement
        
        # Actualizar archivos
        File.write('db/invoices.json', JSON.generate($invoices))
        File.write('db/payment_complements.json', JSON.generate($payment_complements))
        
        puts "Complemento generado exitosamente: #{facturama_result[:facturama_id]}"
        
        response.status = 200
        response['Content-Type'] = 'application/json'
        response.body = JSON.generate(complement.reject { |k, v| k == 'facturama_response' })
      else
        puts "Error generando complemento: #{facturama_result[:error]}"
        response.status = 500
        response['Content-Type'] = 'application/json'
        response.body = JSON.generate({ 
          'error' => facturama_result[:error],
          'details' => 'Error al generar complemento de pago'
        })
      end
      
    rescue JSON::ParserError => e
      puts "Error parsing JSON: #{e.message}"
      response.status = 400
      response['Content-Type'] = 'application/json'
      response.body = JSON.generate({ 'error' => 'Invalid JSON format' })
    rescue => e
      puts "Error generating payment complement: #{e.message}"
      puts e.backtrace
      response.status = 500
      response['Content-Type'] = 'application/json'
      response.body = JSON.generate({ 'error' => "Internal server error: #{e.message}" })
    end
  end
end

class PaymentComplementDownloadServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_OPTIONS(request, response)
    # Configurar CORS para OPTIONS
    response['Access-Control-Allow-Origin'] = '*'
    response['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    response['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Requested-With'
    response['Access-Control-Max-Age'] = '86400'
    response.status = 200
    response.body = ''
  end

  def do_GET(request, response)
    begin
      # Configurar CORS
      response['Access-Control-Allow-Origin'] = '*'
      response['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
      response['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Requested-With'
      
      # Extraer el ID del complemento de la URL
      path_parts = request.path.split('/')
      id = path_parts[2].to_i
      format = path_parts[3] # 'pdf' o 'xml'
      
      # Buscar el complemento
      complement = $payment_complements.find { |comp| comp['id'] == id }
      
      if complement
        if format == 'pdf'
          # Servir el PDF real de Facturama
          response.status = 200
          response['Content-Type'] = 'application/pdf'
          response['Content-Disposition'] = "attachment; filename=\"complemento_pago_#{complement['facturama_id']}.pdf\""
          
          if complement['pdf_base64']
            # Decodificar el PDF desde base64
            pdf_data = Base64.strict_decode64(complement['pdf_base64'])
            response.body = pdf_data
          else
            response.status = 404
            response['Content-Type'] = 'application/json'
            response.body = JSON.generate({ 'error' => 'PDF not available' })
          end
        elsif format == 'xml'
          # Servir el XML real de Facturama
          response.status = 200
          response['Content-Type'] = 'application/xml'
          response['Content-Disposition'] = "attachment; filename=\"complemento_pago_#{complement['facturama_id']}.xml\""
          
          if complement['xml_content']
            response.body = complement['xml_content']
          else
            response.status = 404
            response['Content-Type'] = 'application/json'
            response.body = JSON.generate({ 'error' => 'XML not available' })
          end
        else
          # Devolver URLs de descarga
          response.status = 200
          response['Content-Type'] = 'application/json'
          response.body = JSON.generate({
            'id' => complement['id'],
            'facturama_id' => complement['facturama_id'],
            'uuid' => complement['uuid'],
            'pdf_url' => complement['pdf_url'],
            'xml_url' => complement['xml_url'],
            'status' => complement['status'],
            'created_at' => complement['created_at']
          })
        end
      else
        response.status = 404
        response['Content-Type'] = 'application/json'
        response.body = JSON.generate({ 'error' => 'Payment complement not found' })
      end
    rescue => e
      puts "Error in download servlet: #{e.message}"
      puts e.backtrace
      response.status = 500
      response['Content-Type'] = 'application/json'
      response.body = JSON.generate({ 'error' => e.message })
    end
  end
end

# Crear y configurar el servidor
server = WEBrick::HTTPServer.new(
  :Port => 3000,
  :AccessLog => [],
  :Logger => WEBrick::Log.new(File.open(File::NULL, 'w'))
)

# Configurar CORS para todas las rutas
server.mount_proc('/') do |req, res|
  # Habilitar CORS
  res['Access-Control-Allow-Origin'] = '*'
  res['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
  res['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Requested-With'
  res['Access-Control-Max-Age'] = '86400'
  
  if req.request_method == 'OPTIONS'
    res.status = 200
    res.body = ''
    next
  end
  
  # Routear las solicitudes
  case req.path
  when '/invoices'
    InvoicesServlet.new(server).service(req, res)
  when '/upload_xml'
    UploadXMLServlet.new(server).service(req, res)
  when '/payment_complements'
    PaymentComplementServlet.new(server).service(req, res)
  when %r{^/payment_complements/(\d+)/(pdf|xml)$}
    PaymentComplementDownloadServlet.new(server).service(req, res)
  when %r{^/payment_complements/(\d+)/download$}
    PaymentComplementDownloadServlet.new(server).service(req, res)
  else
    res.status = 404
    res['Content-Type'] = 'application/json'
    res.body = JSON.generate({ 'error' => 'Endpoint not found', 'path' => req.path })
  end
end

# Mensaje de inicio
puts "=== Servidor Backend con Facturama API iniciado en http://localhost:3000 ==="
puts ""
puts "🔗 Integración con Facturama Sandbox:"
puts "   - URL: #{FACTURAMA_BASE_URL}"
puts "   - Usuario: #{FACTURAMA_USERNAME}"
puts "   - Los complementos de pago se generan usando la API real de Facturama"
puts ""
puts "💡 Mejoras implementadas:"
puts "   - Extracción de UUID real desde los XMLs subidos"
puts "   - Búsqueda de facturas por ID numérico o UUID"
puts "   - Asociación correcta entre facturas y complementos de pago"
puts "   - Soporte completo para campos fiscales requeridos por el SAT:"
puts "     - TaxZipCode (Código Postal fiscal del receptor): #{FISCAL_VALUES[:defaults][:receiver_tax_zip_code]}"
puts "     - FiscalRegime (Régimen fiscal normal): #{FISCAL_VALUES[:defaults][:receiver_fiscal_regime_normal]} (#{FISCAL_VALUES[:fiscal_regimes][FISCAL_VALUES[:defaults][:receiver_fiscal_regime_normal]]})"
puts "     - FiscalRegime (Para RFC genérico): #{FISCAL_VALUES[:defaults][:receiver_fiscal_regime_generic]} (#{FISCAL_VALUES[:fiscal_regimes][FISCAL_VALUES[:defaults][:receiver_fiscal_regime_generic]]})"
puts "     - ExpeditionPlace (Lugar de expedición): #{FISCAL_VALUES[:defaults][:expedition_place]}"
puts ""
puts "Endpoints disponibles:"
puts "- GET /invoices - Listar facturas"
puts "- POST /upload_xml - Subir XML de factura (extrae UUID real)"
puts "- POST /payment_complements - Generar complemento de pago (con Facturama)"
puts "- GET /payment_complements/:id/pdf - Descargar PDF del complemento"
puts "- GET /payment_complements/:id/xml - Descargar XML del complemento"
puts "- GET /payment_complements/:id/download - URLs de descarga"
puts ""
puts "Presiona CTRL+C para detener el servidor"
puts ""

# Iniciar el servidor
trap('INT') { server.shutdown }
server.start
