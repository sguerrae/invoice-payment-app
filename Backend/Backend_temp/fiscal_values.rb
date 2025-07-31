# Configuración de valores fiscales para la API de Facturama
FISCAL_VALUES = {
  # Regímenes fiscales comunes según el SAT
  fiscal_regimes: {
    "601" => "General de Ley Personas Morales",
    "603" => "Personas Morales con Fines no Lucrativos",
    "605" => "Sueldos y Salarios",
    "612" => "Personas Físicas con Actividades Empresariales y Profesionales",
    "616" => "Sin obligaciones fiscales",
    "621" => "Incorporación Fiscal",
    "625" => "Régimen Simplificado de Confianza"
  },
  
  # Formas de pago comunes según el SAT
  payment_forms: {
    "01" => "Efectivo",
    "02" => "Cheque nominativo",
    "03" => "Transferencia electrónica de fondos",
    "04" => "Tarjeta de crédito",
    "05" => "Monedero electrónico",
    "06" => "Dinero electrónico",
    "28" => "Tarjeta de débito",
    "29" => "Tarjeta de servicios",
    "99" => "Por definir"
  },
  
  # Métodos de pago comunes según el SAT
  payment_methods: {
    "PUE" => "Pago en una sola exhibición",
    "PPD" => "Pago en parcialidades o diferido"
  },
  
  # Usos de CFDI comunes según el SAT
  cfdi_uses: {
    "G01" => "Adquisición de mercancías",
    "G03" => "Gastos en general",
    "P01" => "Por definir",
    "CP01" => "Pagos (específico para complementos)"
  },
  
  # Valores por defecto para Facturama
  defaults: {
    expedition_place: "78000",  # Código postal para la expedición del CFDI
    receiver_tax_zip_code: "78000",  # Código postal fiscal del receptor
    receiver_fiscal_regime_normal: "601",  # Régimen fiscal normal (General de Ley Personas Morales)
    receiver_fiscal_regime_generic: "616"  # Régimen fiscal para RFC genérico (Sin obligaciones fiscales)
  }
}

# Validación para códigos postales y RFCs genéricos
def validate_fiscal_data(data)
  errors = []
  
  # Validación para RFC genérico (XAXX010101000 o XEXX010101000)
  if ["XAXX010101000", "XEXX010101000"].include?(data[:rfc_receptor])
    if data[:expedition_place] != data[:receiver_tax_zip_code]
      errors << "Para RFC genérico (#{data[:rfc_receptor]}), ExpeditionPlace debe ser igual a TaxZipCode"
      # Corregir automáticamente
      data[:expedition_place] = data[:receiver_tax_zip_code]
    end
    
    # Para RFC genérico, usar régimen fiscal 616 (Sin obligaciones fiscales)
    if data[:receiver_fiscal_regime] != "616"
      errors << "Para RFC genérico (#{data[:rfc_receptor]}), el régimen fiscal debe ser 616 (Sin obligaciones fiscales)"
      # Corregir automáticamente
      data[:receiver_fiscal_regime] = "616"
    end
  end
  
  # Verificar que el código postal sea válido (5 dígitos)
  unless data[:receiver_tax_zip_code].to_s =~ /^\d{5}$/
    errors << "El código postal fiscal debe tener 5 dígitos"
    # Usar valor por defecto
    data[:receiver_tax_zip_code] = FISCAL_VALUES[:defaults][:receiver_tax_zip_code]
  end
  
  # Verificar que el régimen fiscal sea válido
  unless FISCAL_VALUES[:fiscal_regimes].key?(data[:receiver_fiscal_regime])
    errors << "El régimen fiscal proporcionado no es válido"
    
    # Usar valor por defecto según el tipo de RFC
    if ["XAXX010101000", "XEXX010101000"].include?(data[:rfc_receptor])
      data[:receiver_fiscal_regime] = FISCAL_VALUES[:defaults][:receiver_fiscal_regime_generic]
    else
      data[:receiver_fiscal_regime] = FISCAL_VALUES[:defaults][:receiver_fiscal_regime_normal]
    end
  end
  
  return data, errors
end
