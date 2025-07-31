import React, { useState } from 'react';
import { FileUpload } from '../ui/file-upload';

export function InvoiceUpload({ onUpload }) {
  const [isUploading, setIsUploading] = useState(false);
  const [error, setError] = useState('');

  const handleFileChange = async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    
    if (!file.name.endsWith('.xml')) {
      setError('Solo se permiten archivos XML');
      return;
    }

    setIsUploading(true);
    setError('');
    
    try {
      const formData = new FormData();
      formData.append('invoice', file);
      
      // En una aplicación real, aquí se haría una llamada a la API para subir el archivo
      // Para este ejemplo, simulamos una respuesta exitosa después de un breve retraso
      setTimeout(() => {
        // Simulamos una respuesta exitosa con datos de factura
        const mockInvoice = {
          id: Math.random().toString(36).substring(7),
          filename: file.name,
          client: 'Empresa Cliente S.A. de C.V.',
          date: new Date().toISOString().split('T')[0],
          uuid: Math.random().toString(36).substring(2, 15) + 
                Math.random().toString(36).substring(2, 15),
          subtotal: parseFloat((Math.random() * 10000).toFixed(2)),
          total: parseFloat((Math.random() * 12000).toFixed(2)),
          paid: false
        };
        
        if (onUpload) {
          onUpload(mockInvoice);
        }
        
        setIsUploading(false);
      }, 1500);
    } catch (err) {
      console.error("Error al subir la factura:", err);
      setError('Error al subir la factura XML');
      setIsUploading(false);
    }
  };

  return (
    <div className="space-y-4">
      <div className="space-y-2">
        <h2 className="text-2xl font-bold">Subir Factura</h2>
        <p className="text-muted-foreground">
          Sube archivos XML de facturas PPD para procesarlos
        </p>
      </div>
      
      <FileUpload
        accept=".xml"
        onChange={handleFileChange}
        className={isUploading ? "opacity-50 pointer-events-none" : ""}
      />
      
      {isUploading && (
        <div className="flex items-center justify-center">
          <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-primary"></div>
          <span className="ml-2">Subiendo...</span>
        </div>
      )}
      
      {error && (
        <div className="p-3 bg-destructive/10 text-destructive rounded-md">
          {error}
        </div>
      )}
    </div>
  );
}
