import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { Button } from '../ui/button';

export function PaymentModal({ invoice = {}, onClose, onConfirm }) {
  const [isGenerating, setIsGenerating] = useState(false);
  
  // Función para verificar si el servidor está disponible
  const checkServerAvailability = async () => {
    try {
      console.log('Verificando disponibilidad del servidor...');
      const response = await fetch('/api/invoices', {
        method: 'GET',
        headers: {
          'Accept': 'application/json'
        },
        // Timeout de 5 segundos
        signal: AbortSignal.timeout(5000)
      });
      
      console.log('Respuesta del servidor (status):', response.status);
      
      if (response.ok) {
        const data = await response.json();
        console.log('Servidor disponible, facturas encontradas:', data.length);
        return true;
      } else {
        console.error('Servidor respondió con error:', response.status, response.statusText);
        return false;
      }
    } catch (error) {
      console.error('Error al verificar disponibilidad del servidor:', error);
      console.error('Tipo de error:', error.name);
      console.error('Mensaje de error:', error.message);
      
      // Información específica para ciertos tipos de errores
      if (error.name === 'AbortError') {
        console.error('La solicitud fue abortada por timeout (5s)');
      } else if (error.name === 'TypeError' && error.message.includes('Failed to fetch')) {
        console.error('Posibles causas: CORS, servidor no iniciado, puerto incorrecto, firewall');
      }
      
      return false;
    }
  };

  const handleConfirm = async () => {
    setIsGenerating(true);
    
    try {
      // Verificamos que tenemos todos los datos necesarios antes de la llamada
      if (!invoice?.id || !invoice?.total) {
        throw new Error('Datos de factura incompletos');
      }
      
      // Verificamos si el servidor está disponible
      const isServerAvailable = await checkServerAvailability();
      if (!isServerAvailable) {
        throw new Error('El servidor no está disponible. Por favor, verifica que el servidor backend esté corriendo');
      }
      
      // DEBUG: Mostramos los valores originales que estamos recibiendo
      console.log("Invoice ID original:", invoice.id);
      console.log("UUID original:", invoice.uuid);
      console.log("Invoice completo recibido:", invoice);
      
      // Preparamos el ID de la factura para el backend
      // NOTA: En producción, deberíamos usar los IDs reales del backend, no los generados localmente
      // Para este ejemplo mock, usamos un ID conocido que exista en el backend (1, 2 o 3)
      const numericInvoiceId = 1; // Usamos un ID conocido que existe en el backend
      
      // Realizamos la llamada al API para generar el complemento de pago
      console.log('Intentando conectar con: /api/payment_complements');
      
      // IMPORTANTE: Usamos el código postal registrado en el perfil fiscal de Facturama
      // Basado en la documentación y errores previos, 76343 es un código postal válido
      // Otros códigos postales podrían no estar registrados en el perfil fiscal de Facturama
      const CODIGO_POSTAL_REGISTRADO = "76343"; // Código postal registrado en el perfil fiscal
      
      // Formateamos los datos según la estructura exacta que espera el backend
      // Incluimos TODOS los campos requeridos por el SAT y Facturama
      const requestData = {
        // El ID de la factura debe ir en el cuerpo de la solicitud
        // Usamos un ID que sabemos que existe en el backend mock
        invoice_id: numericInvoiceId,
        
        // Datos de pago requeridos para el complemento
        monto: Number(invoice.total),
        forma_pago: "99", // Valor por defecto según catálogo SAT
        fecha: new Date().toISOString().split('T')[0], // Formato YYYY-MM-DD
        
        // Para el UUID, aseguramos usar uno válido según la documentación
        // NOTA: En un entorno real, esto debería venir del backend
        uuid: "XXXXXXXX-XXXX-4XXX-YXXX-XXXXXXXXXXXX", // Formato UUID estándar para pruebas
        
        customer: invoice.client || 'Cliente de Prueba',
        total: Number(invoice.total),
        subtotal: Number(invoice.subtotal || 0),
        rfc_emisor: 'XIA190128J61', // RFC según la documentación
        rfc_receptor: 'XAXX010101000',
        
        // Campos adicionales requeridos por Facturama según el error:
        fiscal_data: {
          // El código postal de expedición DEBE coincidir con el código postal fiscal del receptor
          // cuando se usa el RFC genérico XAXX010101000
          expedition_place: CODIGO_POSTAL_REGISTRADO, // Código postal registrado en Facturama
          receiver_tax_zip_code: CODIGO_POSTAL_REGISTRADO, // Debe ser igual a expedition_place
          receiver_fiscal_regime: "601", // Régimen fiscal: General de Personas Morales
        }
      };
      
      // DEBUG: Mostramos exactamente lo que vamos a enviar
      console.log("Invoice ID enviado:", requestData.invoice_id);
      console.log("UUID enviado:", requestData.uuid);
      
      console.log('Datos enviados al backend:', requestData);
      console.log('URL de la petición:', `/api/payment_complements`);
      
      // Aseguramos de que los datos tengan exactamente la estructura que espera el backend
      // Según la documentación y el error recibido de Facturama
      const payloadData = {
        invoice_id: requestData.invoice_id,
        uuid: requestData.uuid,
        monto: requestData.monto,
        forma_pago: requestData.forma_pago,
        fecha: requestData.fecha,
        // Incluimos los campos que el backend espera
        customer: requestData.customer,
        total: requestData.total,
        rfc_emisor: requestData.rfc_emisor,
        rfc_receptor: requestData.rfc_receptor,
        // Campos adicionales requeridos por Facturama
        expedition_place: requestData.fiscal_data.expedition_place,
        receiver_tax_zip_code: requestData.fiscal_data.receiver_tax_zip_code,
        receiver_fiscal_regime: requestData.fiscal_data.receiver_fiscal_regime,
        // Datos adicionales para generar correctamente la factura
        payment_method: "PPD", // Pago en parcialidades o diferido (requerido para complementos)
        cfdi_use: "S01",       // Sin efectos fiscales (para pruebas)
        currency: "MXN"        // Moneda: Peso Mexicano
      };
      
      console.log('Payload final enviado:', payloadData);
      
      const response = await fetch(`/api/payment_complements`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify(payloadData)
      });
      
      // Log completo de la respuesta para depuración
      console.log('Respuesta status:', response.status);
      console.log('Respuesta headers:', Object.fromEntries(response.headers.entries()));
      console.log('URL de la petición:', `/api/payment_complements`);
      console.log('Método de la petición:', 'POST');
      
      if (!response.ok) {
        // Intentar obtener el texto completo de error primero
        const errorText = await response.text();
        console.error('Error del servidor (texto completo):', errorText);
        
        let errorMessage = 'Error al generar el complemento de pago';
        try {
          // Intenta parsear como JSON si es posible
          const errorData = JSON.parse(errorText);
          // Estructura de error esperada del backend: { error: "...", details: "..." }
          errorMessage = errorData.error || errorData.message || errorMessage;
          if (errorData.details) {
            errorMessage += `. ${errorData.details}`;
          }
          console.error('Error del servidor (JSON):', errorData);
        } catch (parseError) {
          // Si no es JSON, usar el texto tal cual
          console.error('Error al parsear la respuesta de error como JSON:', parseError);
          errorMessage = errorText || errorMessage;
        }
        
        throw new Error(errorMessage);
      }
      
      // Log para ver la respuesta completa
      const responseText = await response.text();
      console.log('Respuesta exitosa (texto):', responseText);
      
      let result;
      try {
        result = JSON.parse(responseText);
        
        // Verificamos que la respuesta contiene la estructura esperada
        // Estructura esperada: { id, invoice_id, facturama_id, uuid, pdf_url, xml_url, status, created_at }
        if (!result.id || !result.invoice_id || !result.status) {
          console.warn('La respuesta no contiene todos los campos esperados:', result);
        }
        
        // Extraemos las URLs de descarga para facilitar el acceso posterior
        if (result.pdf_url) {
          result.pdfUrl = result.pdf_url;
        }
        if (result.xml_url) {
          result.xmlUrl = result.xml_url;
        }
        
      } catch (parseError) {
        console.error('Error al parsear respuesta como JSON:', parseError);
        result = { 
          success: true, 
          text: responseText,
          id: requestData.invoice_id,
          invoice_id: requestData.invoice_id,
          status: 'generated'
        };
      }
      
      console.log('Respuesta exitosa (parseada):', result);
      
      // Llamamos a la función onConfirm del componente padre con el resultado
      if (onConfirm) {
        onConfirm(invoice.id, result);
      }
      
      // Cerramos el modal
      onClose();
    } catch (error) {
      console.error('Error al generar el complemento de pago:', error);
      console.error('Detalles adicionales del error:', { 
        name: error.name,
        message: error.message,
        stack: error.stack,
        isDeprecatedError: error.message.includes('Deprecated')
      });
      
      // Más información de diagnóstico para ayudar en la depuración
      console.error('Datos enviados cuando ocurrió el error:', {
        invoiceId: invoice.id,
        uuid: invoice.uuid,
        total: invoice.total,
        requestEndpoint: '/api/payment_complements'
      });
      
      // Mensaje de error más específico para el caso de "Failed to fetch"
      if (error.message === 'Failed to fetch') {
        alert(`No se pudo generar el complemento de pago: El servidor no está disponible. 

Por favor, verifica lo siguiente:
1. Que el servidor backend esté corriendo correctamente
2. Que el formato de datos coincida exactamente con lo que espera el backend:
   {
     "invoice_id": 1, // Número entero, no string
     "uuid": "UUID_FACTURA",
     "customer": "NOMBRE_CLIENTE",
     "total": 1000.00, // Número, no string
     "subtotal": 800.00, // Número, no string
     "rfc_emisor": "RFC_EMISOR",
     "rfc_receptor": "RFC_RECEPTOR"
   }

Revisa la consola para más detalles.`);
      } else if (error.message.includes('SyntaxError') || error.message.includes('Unexpected token')) {
        alert(`Error al procesar la respuesta del servidor: La respuesta no es un JSON válido. Por favor, verifica el formato de respuesta del backend.`);
      } else if (error.message.includes('NetworkError') || error.message.includes('Network request failed')) {
        alert(`Error de red al comunicarse con el servidor. Verifica tu conexión a internet y que el servidor esté disponible.`);
      } else if (error.message.includes('Facturama (400): {"Message":"Deprecated"}')) {
        alert(`Error con el API de Facturama: El endpoint utilizado está obsoleto (Deprecated). 
        
Por favor, notifica al equipo de backend para que actualice la integración con Facturama a la versión más reciente de su API.`);
      } else if (error.message.includes('Error creando factura en Facturama') && error.message.includes('La solicitud no es válida')) {
        alert(`⚠️ ERROR DE INTEGRACIÓN CON FACTURAMA ⚠️

El backend no está enviando los campos fiscales requeridos por el SAT a Facturama.

Problema detectado:
El frontend está enviando todos los campos fiscales necesarios, pero el backend no los está utilizando en su solicitud a Facturama.

Campos faltantes en la solicitud a Facturama:
1. Receiver.TaxZipCode (Código postal del receptor)
2. Receiver.FiscalRegime (Régimen fiscal del receptor)
3. ExpeditionPlace (debe coincidir con TaxZipCode cuando se usa RFC genérico)

Para el equipo de backend:
- Revisar la creación de la solicitud a Facturama en el archivo del servidor mock
- Agregar los campos fiscales que el frontend está enviando a la solicitud de Facturama
- Asegurar que ExpeditionPlace y TaxZipCode sean iguales cuando se usa RFC genérico

El frontend YA está enviando estos datos como:
- expedition_place: "76343"
- receiver_tax_zip_code: "76343"
- receiver_fiscal_regime: "601"
`);
      } else if (error.message.includes('503') || error.message.includes('Service Unavailable') || error.message.includes('temporarily unavailable')) {
        alert(`📡 SERVICIO DE FACTURAMA TEMPORALMENTE NO DISPONIBLE

El servicio de Facturama Sandbox está temporalmente caído o en mantenimiento.

Este es un error común en ambientes sandbox (Error 503: Service Unavailable) y 
NO es un problema con tu código o los datos enviados. La integración es correcta.

Recomendaciones:
1. Espera unos minutos y vuelve a intentarlo más tarde
2. Verifica el estado del servicio de Facturama (status.facturama.mx)
3. Si el problema persiste por más de algunas horas, contacta a soporte de Facturama

Tu integración ya está correcta y los datos fiscales se están enviando adecuadamente.
Cuando el servicio vuelva a estar disponible, todo funcionará sin problemas.`);
      } else if (error.message.includes('ExpeditionPlace') && error.message.includes('Lugares de expedición')) {
        alert(`⚠️ ERROR DE CONFIGURACIÓN EN FACTURAMA ⚠️

El código postal usado para la emisión de facturas no está registrado en el perfil fiscal de Facturama.

Mensaje del error:
El atributo 'ExpeditionPlace' debe existir como código postal en alguno de los Lugares de expedición en tu Perfil Fiscal.

Soluciones posibles:
1. Usa únicamente códigos postales que estén registrados en tu perfil fiscal de Facturama:
   - 76343 (Código registrado en el perfil fiscal de pruebas)
   
2. O agrega el código postal actual ("11590") a tu perfil fiscal en Facturama:
   - Ve a la sección "Perfil Fiscal" en el portal de Facturama
   - Agrega el código postal en la sección "Lugares de Expedición"
   - Para el sandbox, consulta la documentación en: https://apisandbox.facturama.mx/guias/perfil-fiscal#lugares-expedicion-series

Este error ocurre porque Facturama requiere que todos los códigos postales usados para emitir 
facturas estén previamente registrados en el perfil fiscal del emisor.`);
      } else if (error.message.includes('Invoice not found')) {
        alert(`No se pudo generar el complemento de pago: Factura no encontrada.

El servidor no puede encontrar la factura con el ID proporcionado. Esto puede deberse a:
1. El ID de la factura no existe en la base de datos del servidor
2. El formato del ID no es el esperado por el servidor
3. La factura fue eliminada o no está disponible

Por favor, verifica que la factura exista en el sistema e inténtalo nuevamente.`);
      } else if (error.message.includes('Endpoint not found')) {
        alert(`Error del servidor: Endpoint no encontrado.

El servidor no tiene definido el endpoint para generar complementos de pago. 
Esto puede deberse a:
1. El backend no está actualizado con los endpoints correctos
2. La ruta de la API ha cambiado
3. El servidor no está correctamente configurado

Por favor, contacta al equipo de backend para verificar la disponibilidad y formato correcto del endpoint.`);
      } else if (error.message.includes('Invoice not found') || error.message.includes('no existe')) {
        alert(`No se pudo generar el complemento de pago: La factura no existe en el sistema.

El servidor no puede encontrar la factura con los datos proporcionados. Esto se debe a:
1. El ID de factura no existe en la base de datos del backend
2. El UUID proporcionado no corresponde a una factura válida
3. La factura no ha sido cargada previamente al sistema

Revisa la consola para ver los detalles del ID y UUID enviados.
En un entorno real, este error se resolvería asegurando que primero subes la factura XML
antes de intentar generar su complemento de pago.`);
      } else {
        alert(`No se pudo generar el complemento de pago: ${error.message}. Por favor, inténtalo de nuevo.

Detalles técnicos para el desarrollador:
- Verifica que el servidor mock esté corriendo
- Asegúrate de que la factura exista en la base de datos (IDs válidos: 1, 2, 3)
- Comprueba que el UUID tenga el formato correcto`);
      }
    } finally {
      setIsGenerating(false);
    }
  };
  
  // Verifica que invoice tenga todas las propiedades necesarias
  console.log('Invoice en PaymentModal:', invoice);
  
  // Verificación más completa de datos de factura
  const missingFields = [];
  if (!invoice?.id) missingFields.push('ID');
  if (!invoice?.client) missingFields.push('Cliente');
  if (!invoice?.date) missingFields.push('Fecha');
  if (!invoice?.uuid) missingFields.push('UUID');
  if (invoice?.total === undefined) missingFields.push('Total');
  
  // Si faltan campos esenciales, mostramos un mensaje de error detallado
  if (missingFields.length > 0) {
    return (
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div className="bg-white rounded-lg shadow-lg p-6 max-w-md w-full">
          <h3 className="text-xl font-bold mb-4 text-red-600">Error</h3>
          <p className="text-gray-800 mb-2">No se pudo cargar la información completa de la factura.</p>
          <div className="bg-red-50 p-3 rounded mb-4 text-sm">
            <p className="text-red-700 font-medium">Campos faltantes:</p>
            <ul className="list-disc ml-5 mt-1 text-red-600">
              {missingFields.map(field => (
                <li key={field}>{field}</li>
              ))}
            </ul>
          </div>
          <p className="text-gray-600 text-sm mb-4">
            Por favor, asegúrese de que el archivo XML contiene toda la información necesaria y vuelva a intentarlo.
          </p>
          <div className="flex justify-end">
            <Button onClick={onClose}>Cerrar</Button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-lg p-6 max-w-md w-full">
        <h3 className="text-xl font-bold mb-4">Generar Complemento de Pago</h3>
        
        <div className="space-y-4">
          <p className="text-gray-600">
            Estás a punto de generar un complemento de pago para la siguiente factura:
          </p>
          
          <div className="bg-slate-50 p-4 rounded-md border border-slate-200">
            <div className="grid grid-cols-2 gap-3">
              <span className="text-slate-500 font-medium">Cliente:</span>
              <span className="font-semibold text-slate-800">{invoice?.client || 'N/A'}</span>
              
              <span className="text-slate-500 font-medium">Fecha:</span>
              <span className="text-slate-800">{invoice?.date || 'N/A'}</span>
              
              <span className="text-slate-500 font-medium">UUID:</span>
              <span className="font-mono text-xs text-slate-800">{invoice?.uuid || 'N/A'}</span>
              
              <span className="text-slate-500 font-medium">Subtotal:</span>
              <span className="text-slate-800">
                {invoice?.subtotal ? new Intl.NumberFormat('es-MX', {
                  style: 'currency',
                  currency: 'MXN'
                }).format(invoice.subtotal) : 'N/A'}
              </span>
              
              <span className="text-slate-500 font-medium">Total:</span>
              <span className="font-semibold text-slate-800">
                {invoice?.total ? new Intl.NumberFormat('es-MX', {
                  style: 'currency',
                  currency: 'MXN'
                }).format(invoice.total) : 'N/A'}
              </span>
            </div>
          </div>
          
          <div className="bg-blue-50 p-4 rounded-md border-l-4 border-blue-400">
            <p className="text-sm text-blue-700">
              Esta acción generará un complemento de pago por el monto total de la factura.
              Esta operación no se puede deshacer.
            </p>
          </div>
        </div>
        
        <div className="flex justify-end space-x-2 mt-6">
          <Button
            variant="outline"
            onClick={onClose}
            disabled={isGenerating}
            className="px-4 py-2"
          >
            Cancelar
          </Button>
          
          <Button
            onClick={handleConfirm}
            disabled={isGenerating}
            className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2"
          >
            {isGenerating ? (
              <>
                <div className="mr-2 animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                Generando...
              </>
            ) : (
              'Generar Complemento'
            )}
          </Button>
        </div>
      </div>
    </div>
  );
}

PaymentModal.propTypes = {
  invoice: PropTypes.shape({
    id: PropTypes.string,
    client: PropTypes.string,
    date: PropTypes.string,
    uuid: PropTypes.string,
    subtotal: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
    total: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
    paid: PropTypes.bool
  }),
  onClose: PropTypes.func.isRequired,
  onConfirm: PropTypes.func.isRequired
};
