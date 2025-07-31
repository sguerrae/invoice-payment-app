import { useState } from 'react';
import './App.css';

// Import components
import { InvoiceUpload } from './components/invoice/invoice-upload';
import { InvoiceTable } from './components/invoice/invoice-table';
import { PaymentModal } from './components/invoice/payment-modal';

function App() {
  const [invoices, setInvoices] = useState([]);
  const [selectedInvoice, setSelectedInvoice] = useState(null);
  const [showPaymentModal, setShowPaymentModal] = useState(false);

  const handleInvoiceUpload = (invoice) => {
    setInvoices(prevInvoices => [invoice, ...prevInvoices]);
  };

  const handleGeneratePayment = (invoiceId) => {
    const invoice = invoices.find(inv => inv.id === invoiceId);
    
    if (!invoice) {
      console.error(`No se encontró la factura con ID: ${invoiceId}`);
      alert('Error: No se pudo encontrar la información de la factura. Por favor, actualice la página e intente nuevamente.');
      return;
    }
    
    // Verificamos que la factura tenga toda la información necesaria
    if (!invoice.total || !invoice.client || !invoice.uuid) {
      console.error('Información de factura incompleta:', invoice);
      alert('Error: La información de la factura está incompleta. Por favor, suba el archivo XML nuevamente.');
      return;
    }
    
    console.log("Factura seleccionada para pago:", invoice);
    setSelectedInvoice(invoice);
    setShowPaymentModal(true);
  };

  const handleConfirmPayment = (invoiceId, result = {}) => {
    console.log(`Complemento de pago generado para factura ID: ${invoiceId}`, result);
    
    // Verificamos que la respuesta sea válida
    if (!result || (typeof result === 'object' && Object.keys(result).length === 0)) {
      console.error('Respuesta vacía del servidor al generar complemento');
      return;
    }
    
    // Información adicional para depuración
    console.log('Campos disponibles en la respuesta del complemento:', Object.keys(result));
    console.log('URLs de descarga:', {
      pdfUrl: result.pdf_url || result.pdfUrl,
      xmlUrl: result.xml_url || result.xmlUrl
    });
    
    // Verificamos que el ID de factura exista
    const invoiceExists = invoices.some(inv => inv.id === invoiceId);
    if (!invoiceExists) {
      console.error(`No se encontró la factura con ID: ${invoiceId}`);
      alert('Error: No se pudo actualizar la información de la factura. Los cambios no se guardaron.');
      return;
    }
    
    // Actualizar el estado de la factura a pagada
    setInvoices(prevInvoices =>
      prevInvoices.map(invoice => 
        invoice.id === invoiceId 
          ? { 
              ...invoice, 
              paid: true,
              // Guardamos información relevante del complemento generado
              complementId: result.id || result.facturama_id || result.complementId || `comp-${Math.random().toString(36).substring(2, 10)}`,
              pdfUrl: result.pdf_url || result.pdfUrl,
              xmlUrl: result.xml_url || result.xmlUrl,
              facturama_id: result.facturama_id,
              complementUuid: result.uuid
            } 
          : invoice
      )
    );
    
    // Cerrar el modal y limpiar la factura seleccionada
    setShowPaymentModal(false);
    setSelectedInvoice(null);
    
    // Notificar al usuario que el complemento fue generado exitosamente
    alert(`¡Complemento de pago generado con éxito!

Factura: ${invoiceId}
Complemento ID: ${result.id || result.facturama_id || 'N/A'}
Estado: ${result.status || 'Completado'}

Ahora puedes descargar el PDF y XML desde el menú de acciones de la factura.`);
  };

  const handleDownload = (invoiceId, format) => {
    // Buscamos la factura para obtener las URLs de descarga almacenadas
    const invoice = invoices.find(inv => inv.id === invoiceId);
    
    if (!invoice) {
      console.error(`No se encontró la factura con ID: ${invoiceId}`);
      alert('Error: No se pudo encontrar la información de la factura para descargar.');
      return;
    }
    
    // Convertimos el ID si es necesario (si tiene caracteres no numéricos)
    let numericId;
    try {
      // Intentamos usar el ID del complemento si existe
      if (invoice.complementId) {
        numericId = invoice.complementId;
      } else {
        numericId = parseInt(invoiceId.replace(/\D/g, ''));
        if (isNaN(numericId)) {
          numericId = invoiceId;
        }
      }
    } catch (parseError) {
      console.error('Error al convertir ID a numérico:', parseError);
      numericId = invoiceId;
    }
    
    // Intentamos usar las URLs guardadas durante la generación del complemento
    let downloadUrl;
    
    if (format === 'pdf' && invoice.pdfUrl) {
      // Usamos la URL proporcionada directamente
      downloadUrl = invoice.pdfUrl;
    } else if (format === 'xml' && invoice.xmlUrl) {
      // Usamos la URL proporcionada directamente
      downloadUrl = invoice.xmlUrl;
    } else {
      // Si no tenemos URLs guardadas, construimos la URL basada en el endpoint del servidor
      if (format === 'pdf') {
        downloadUrl = `/api/payment_complements/${numericId}/pdf`;
      } else if (format === 'xml') {
        downloadUrl = `/api/payment_complements/${numericId}/xml`;
      } else {
        downloadUrl = `/api/payment_complements/${numericId}/download?format=${format}`;
      }
    }
    
    console.log(`Intentando descargar: ${downloadUrl}`);
    
    try {
      // Abrimos una nueva ventana/pestaña para la descarga
      window.open(downloadUrl, '_blank');
    } catch (error) {
      console.error('Error al abrir la URL de descarga:', error);
      alert(`No se pudo abrir la URL de descarga: ${downloadUrl}. Por favor, intenta nuevamente.`);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50">
      <header className="bg-blue-700 text-white py-6 shadow-md">
        <div className="container mx-auto px-4">
          <h1 className="text-2xl md:text-3xl font-bold">XENON INDUSTRIAL ARTICLES</h1>
          <p className="text-sm md:text-base opacity-90">Sistema de Gestión de Facturas</p>
        </div>
      </header>

      <main className="container mx-auto px-4 py-8">
        <div className="grid gap-8 grid-cols-1 lg:grid-cols-[1fr_2fr] md:grid-cols-1">
          <div className="space-y-8">
            <InvoiceUpload onUpload={handleInvoiceUpload} />
            
            <div className="p-4 bg-blue-50 rounded-lg border border-blue-100">
              <h2 className="font-medium mb-2 text-blue-800">Información</h2>
              <div className="text-sm space-y-2 text-blue-700">
                <p>
                  <strong>Empresa:</strong> XENON INDUSTRIAL ARTICLES
                </p>
                <p>
                  <strong>RFC:</strong> XIA190128J61
                </p>
                <p>
                  <strong>Régimen Fiscal:</strong> General de Personas Morales
                </p>
                <p>
                  <strong>Código Postal:</strong> 76343
                </p>
              </div>
            </div>
          </div>
          
          <div className="space-y-4">
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between">
              <h2 className="text-2xl font-bold text-blue-800 mb-2 sm:mb-0">Facturas</h2>
              <div className="text-sm text-blue-600 font-medium bg-blue-50 px-3 py-1 rounded-full">
                Total: {invoices.length} factura(s)
              </div>
            </div>
            
            <InvoiceTable 
              invoices={invoices}
              onGeneratePayment={handleGeneratePayment}
              onDownload={handleDownload}
            />
          </div>
        </div>
      </main>

      {showPaymentModal && (
        <PaymentModal
          invoice={selectedInvoice}
          onClose={() => {
            setShowPaymentModal(false);
            setSelectedInvoice(null);
          }}
          onConfirm={handleConfirmPayment}
        />
      )}
    </div>
  )
}

export default App
