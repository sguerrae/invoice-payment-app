# XENON INDUSTRIAL ARTICLES - Invoice Management System

## Documentación de Integración

Para facilitar la integración y solución de problemas, consulta los siguientes documentos:

- [Guía de Integración con Facturama](./FACTURAMA_INTEGRATION.md) - Detalla los requisitos de campos fiscales y solución de errores comunes
- [Configuración del Perfil Fiscal en Facturama](./FACTURAMA_PROFILE_SETUP.md) - Explica cómo configurar correctamente el perfil fiscal, especialmente los códigos postales

## Arquitectura del Sistema

### Visión General

El sistema sigue una arquitectura de microservicios donde el frontend y backend están claramente separados. Esta separación permite un desarrollo independiente y escalabilidad de ambas partes.

```ascii
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│                 │         │                 │         │                 │
│    Frontend     │ ◄─────► │     Backend     │ ◄─────► │   Facturama     │
│  (React + Vite) │         │  (Ruby on Rails)│         │      API        │
│                 │         │                 │         │                 │
└─────────────────┘         └─────────────────┘         └─────────────────┘
```

### Componentes del Frontend

1. **Módulo de Carga de Facturas**
   - Componente `InvoiceUpload` para subir archivos XML
   - Validación de archivos para asegurar que solo se suban XMLs válidos
   - Comunicación asíncrona con el backend para procesar los archivos

2. **Visualización de Facturas**
   - Componente `InvoiceTable` con diseño responsivo
   - Implementación de estados visuales para facturas pagadas y pendientes
   - Sistema de filtrado y ordenamiento de facturas
   - Menú desplegable por factura con acciones contextuales:
     - Para facturas pendientes: opción para generar Complemento de Pago
     - Para facturas pagadas: opciones para descargar PDF y XML
   - Indicadores visuales que explican el estado actual de cada factura

3. **Gestión de Complementos de Pago**
   - Componente `PaymentModal` para confirmar la generación de complementos
   - Integración con el backend para solicitar la generación
   - Manejo de estados de carga y errores
   - Botón de acción contextual que cambia según el estado de la factura

4. **UI/UX**
   - Implementación de componentes de ShadCN UI
   - Personalización con Tailwind CSS para una interfaz profesional:
     - Menús desplegables con estilos Tailwind para mejorar la experiencia de usuario
     - Botones contextuales con colores diferenciados según la acción
     - Tooltips informativos que explican las acciones disponibles
   - Indicadores visuales para estados de facturas y acciones disponibles
   - Componente `DropdownMenu` con diseño Tailwind personalizado para mostrar acciones relevantes según el contexto

### Componentes del Backend

1. **API RESTful**
   - Endpoints para gestión de facturas y complementos de pago
   - Autenticación y autorización para proteger recursos
   - Validación de datos entrantes

2. **Procesamiento de XML**
   - Parser especializado para extraer información de facturas PPD
   - Validación según estándares del SAT
   - Almacenamiento estructurado de datos

3. **Integración con Facturama**
   - Cliente API para comunicación con servicios de Facturama
   - Generación de complementos de pago según especificaciones fiscales
   - Manejo de respuestas y errores del servicio externo

### Flujo de Datos

1. **Carga de Factura**

   ```text
   Usuario → Sube XML → Frontend valida formato → 
   Backend procesa XML → Extrae datos → Almacena en BD → 
   Devuelve confirmación → Frontend actualiza tabla
   ```

2. **Generación de Complemento de Pago**

   ```text
   Usuario → Solicita complemento → Frontend muestra confirmación → 
   Backend recibe solicitud → Comunica con Facturama → 
   Facturama genera documentos → Backend almacena respuesta → 
   Frontend muestra opciones de descarga
   ```

### Implementación del Menú de Acciones por Factura

El sistema incorpora un menú desplegable contextual para cada factura que cambia dinámicamente según el estado:

1. **Diseño del Menú**
   - Construido con componentes de ShadCN UI (`DropdownMenu`)
   - Estilizado con Tailwind CSS para mantener consistencia con el resto de la interfaz
   - Botones con estilos contextuales (`border-accent`, `text-accent`, `hover:bg-accent/10` para acciones principales)
   - Animaciones suaves al desplegar/colapsar para mejorar la experiencia de usuario
   - Indicadores visuales que muestran claramente las acciones disponibles

2. **Lógica Contextual**

   ```javascript
   {!invoice.paid ? (
     <DropdownMenuItem onClick={() => onGeneratePayment(invoice.id)}>
       Generar Complemento de Pago
     </DropdownMenuItem>
   ) : (
     <>
       <DropdownMenuItem onClick={() => onDownload(invoice.id, 'pdf')}>
         Descargar PDF
       </DropdownMenuItem>
       <DropdownMenuItem onClick={() => onDownload(invoice.id, 'xml')}>
         Descargar XML
       </DropdownMenuItem>
     </>
   )}
   ```

3. **Estados Visuales**
   - Botón `Actions` con borde azul para facturas pendientes (indicando acción importante)
   - Botón neutro para facturas ya pagadas
   - Información contextual bajo el menú que explica las opciones disponibles
   - Estilos específicos de Tailwind:
     - `border-accent text-accent hover:bg-accent/10` para resaltar acciones importantes
     - `border-slate-200 hover:bg-slate-100` para acciones secundarias

4. **Integración con Backend**
   - Llamadas asíncronas al backend cuando se selecciona una acción
   - Endpoints específicos para cada operación:
     - `POST /payment_complements` para generar el complemento
     - `GET /payment_complements/{id}/pdf` para descargar en PDF
     - `GET /payment_complements/{id}/xml` para descargar en XML
   - Manejo de estados de carga con indicadores visuales (spinner de carga)
   - Gestión de errores con mensajes informativos
   - Actualización automática de la interfaz tras completar una acción

### Seguridad Implementada

- Validación de tipos de archivo para prevenir ataques
- Manejo seguro de credenciales de Facturama
- Protección contra inyección de datos en procesamiento XML
- Validación de datos de entrada en todas las API endpoints

### Servidor Mock para Desarrollo

El proyecto utiliza un servidor mock para desarrollo y pruebas, que simula los endpoints del backend:

```bash
# Iniciar el servidor mock
cd Backend
.\mock_server.bat
```

Endpoints disponibles en el servidor mock:

- `GET /invoices` - Listar facturas disponibles
- `POST /upload_xml` - Subir XML de factura
- `POST /payment_complements` - Generar complemento de pago
- `GET /payment_complements/:id/pdf` - Descargar PDF del complemento
- `GET /payment_complements/:id/xml` - Descargar XML del complemento
- `GET /payment_complements/:id/download` - URLs de descarga

El servidor se ejecuta en `http://localhost:3000` y permite probar todas las funcionalidades del frontend sin necesidad de un backend completo.

#### Configuración CORS

El servidor mock incluye una configuración CORS (Cross-Origin Resource Sharing) que permite solicitudes desde cualquier origen, facilitando el desarrollo local. Para cada servlet se implementaron:

- Método `do_OPTIONS` para manejar solicitudes preflight
- Encabezados CORS en todas las respuestas:
  ```
  Access-Control-Allow-Origin: '*'
  Access-Control-Allow-Methods: 'GET, POST, PUT, DELETE, OPTIONS'
  Access-Control-Allow-Headers: 'Content-Type, Authorization, X-Requested-With'
  Access-Control-Max-Age: '86400'
  ```

Esta configuración permite que el frontend (que se ejecuta en `http://localhost:5174`) se comunique directamente con el backend sin restricciones del navegador.

#### Integración con Facturama

Para generar complementos de pago a través de Facturama, el backend debe incluir ciertos campos obligatorios según los requisitos del SAT:

1. **Datos fiscales del receptor:**
   - `TaxZipCode`: Código postal fiscal del receptor (ej. "76343")
   - `FiscalRegime`: Régimen fiscal del receptor (ej. "601" para Régimen General)

2. **Datos de la factura:**
   - `ExpeditionPlace`: Código postal de expedición (debe coincidir con el `TaxZipCode` cuando se usa RFC genérico)

El frontend envía estos campos adicionales en las solicitudes POST a `/payment_complements`:

```json
{
  "invoice_id": 1,
  "monto": 1000.00,
  "forma_pago": "99",
  "fecha": "2025-07-31",
  "expedition_place": "76343",
  "receiver_tax_zip_code": "76343",
  "receiver_fiscal_regime": "601",
  "payment_method": "PPD",
  "cfdi_use": "G01",
  "currency": "MXN"
}
```

**IMPORTANTE:** El backend actualmente no está utilizando estos campos adicionales al construir la solicitud para Facturama, lo que resulta en errores 400 con mensajes como:

- `"cfdiToCreate.Receiver.TaxZipCode": ["El código postal para el receptor es necesario"]`
- `"cfdiToCreate.Receiver.FiscalRegime": ["The FiscalRegime field is required."]`

Para corregir estos errores, el equipo de backend debe modificar la función de creación de facturas en Facturama para incluir estos campos en la solicitud.


## Author

**Said Jair Guerra Escudero**  
Senior Full Stack Developer  

