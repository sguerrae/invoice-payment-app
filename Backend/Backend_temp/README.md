
# Backend Mock Server

Este servidor mock simula el comportamiento de una API Rails para el challenge de conciliación bancaria de XENON INDUSTRIAL ARTICLES.

## Integración con Facturama

Este backend **consulta y utiliza la API oficial de Facturama** para la generación de facturas y complementos de pago. Todas las operaciones fiscales (facturación, complementos, descarga de PDF/XML) se realizan en tiempo real contra el ambiente sandbox de Facturama.

**Importante:**
- El backend requiere credenciales válidas de Facturama (usuario y contraseña) para funcionar.
- El frontend NO se conecta directamente a Facturama, solo el backend realiza las peticiones fiscales.
- Los lugares de expedición y datos fiscales deben estar correctamente configurados en tu cuenta de Facturama para evitar errores de validación.



## Cómo iniciar el servidor

Ejecuta el siguiente comando desde la carpeta Backend:

```sh
.\mock_server.bat
```

Esto iniciará un servidor web en http://localhost:3000

## Endpoints disponibles

- `GET /invoices` - Devuelve un listado de todas las facturas
- `POST /invoices/upload_xml` - Permite subir un archivo XML de factura
- `POST /invoices/:id/generate_payment_complement` - Genera un complemento de pago para una factura
- `GET /payment_complements/:id/download` - Devuelve las URLs para descargar el PDF y XML de un complemento de pago


## Variables de entorno
Crea un archivo `.env` con las credenciales de Facturama:
```
FACTURAMA_USER=xxxxxxxxxxxxxx
FACTURAMA_PASSWORD=xxxxxxxxxxxxxxxxxxxxxxxxxx
```

Estas credenciales se usan únicamente en el backend para autenticar las peticiones a la API de Facturama.

## Despliegue
Puedes desplegar esta app en Heroku, Render, etc.

## Endpoints principales
- POST `/invoices/upload_xml` — Subir y parsear XMLs
- GET `/invoices` — Listar facturas
- POST `/invoices/:id/generate_payment_complement` — Generar complemento de pago
- GET `/payment_complements/:id/download` — Descargar PDF/XML

