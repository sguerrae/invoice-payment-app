# Backend Manual Setup

Para este challenge, vamos a usar un enfoque simplificado debido a problemas con la instalación de Rails:

## Estructura del backend

El backend debe proporcionar los siguientes endpoints para el frontend:

1. `POST /invoices/upload_xml` - Para subir facturas PPD en formato XML
2. `GET /invoices` - Para listar las facturas con su información
3. `POST /invoices/:id/generate_payment_complement` - Para generar complementos de pago
4. `GET /payment_complements/:id/download` - Para descargar los complementos (PDF/XML)

## Implementación sin Rails (opción alternativa)

Si continúas teniendo problemas con Rails, puedes implementar el backend usando Express.js (Node.js):

```bash
# Crear carpeta del backend
mkdir Backend

# Inicializar proyecto Node.js
cd Backend
npm init -y

# Instalar dependencias
npm install express cors multer axios body-parser

# Crear archivo server.js con los endpoints necesarios
```

### Ejemplo de implementación en Express.js

```javascript
// server.js
const express = require('express');
const multer = require('multer');
const cors = require('cors');
const fs = require('fs');
const xml2js = require('xml2js');
const bodyParser = require('body-parser');
const axios = require('axios');

const app = express();
const port = 3000;
const upload = multer({ dest: 'uploads/' });

// Middlewares
app.use(cors());
app.use(bodyParser.json());

// Base de datos en memoria
const invoices = [];
const paymentComplements = [];

// Endpoints
app.post('/invoices/upload_xml', upload.single('file'), (req, res) => {
  try {
    const xmlData = fs.readFileSync(req.file.path, 'utf8');
    
    // Parsear XML (implementar con xml2js)
    // Extraer UUID, cliente, fecha, subtotal, total
    
    const invoice = {
      id: invoices.length + 1,
      uuid: 'UUID-example',
      customer: 'Cliente Ejemplo',
      issue_date: '2025-07-29',
      subtotal: 1000,
      total: 1160,
      paid: false
    };
    
    invoices.push(invoice);
    res.status(201).json(invoice);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

app.get('/invoices', (req, res) => {
  res.json(invoices);
});

app.post('/invoices/:id/generate_payment_complement', async (req, res) => {
  try {
    const id = parseInt(req.params.id);
    const invoice = invoices.find(inv => inv.id === id);
    
    if (!invoice) {
      return res.status(404).json({ error: 'Factura no encontrada' });
    }
    
    // Llamar a Facturama API para crear complemento
    // const facturama = await createFacturamaComplement(invoice);
    
    const complement = {
      id: paymentComplements.length + 1,
      invoice_id: id,
      facturama_id: 'FACT-' + Math.random().toString(36).substring(7),
      pdf_url: 'https://example.com/pdf',
      xml_url: 'https://example.com/xml'
    };
    
    paymentComplements.push(complement);
    invoice.paid = true;
    
    res.json(complement);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/payment_complements/:id/download', (req, res) => {
  try {
    const id = parseInt(req.params.id);
    const complement = paymentComplements.find(c => c.id === id);
    
    if (!complement) {
      return res.status(404).json({ error: 'Complemento no encontrado' });
    }
    
    res.json({
      pdf_url: complement.pdf_url,
      xml_url: complement.xml_url
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(port, () => {
  console.log(`Backend corriendo en http://localhost:${port}`);
});
```

## Integración con Facturama

Para la integración con Facturama, usa los siguientes datos:

```
Username: apimeefi
Password: 00e751c795a09cabc5fad9cadfd1aba9
```

La documentación de Facturama está disponible en: https://apisandbox.facturama.mx/docs
