# Solución al Problema de CORS

## Problema

El frontend que se ejecuta en `http://localhost:5174` (servidor de desarrollo de Vite) no podía hacer solicitudes directas al backend en `http://localhost:3000` debido a las restricciones de CORS del navegador.

## Solución Implementada

Hemos implementado los encabezados CORS necesarios en el servidor backend (mock_server.rb) para permitir solicitudes desde cualquier origen.

## Cambios realizados

1. **Configuración de CORS en cada servlet del servidor backend:**

```ruby
# Método OPTIONS para solicitudes preflight
def do_OPTIONS(request, response)
  # Configurar CORS para OPTIONS
  response['Access-Control-Allow-Origin'] = '*'
  response['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
  response['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Requested-With'
  response['Access-Control-Max-Age'] = '86400'
  response.status = 200
  response.body = ''
end

# Encabezados CORS en todas las respuestas
response['Access-Control-Allow-Origin'] = '*'
response['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
response['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Requested-With'
```

2. **Implementación de encabezados CORS en todos los servlets:**
   - InvoicesServlet
   - UploadXMLServlet
   - PaymentComplementServlet
   - PaymentComplementDownloadServlet

## Cómo funciona

1. Cuando el navegador detecta una solicitud cross-origin, primero envía una solicitud OPTIONS (preflight)
2. El servidor responde con los encabezados CORS apropiados indicando qué está permitido
3. Si todo está correctamente configurado, el navegador procede con la solicitud real (GET, POST, etc.)
4. El servidor incluye los encabezados CORS en su respuesta normal
5. El navegador permite que el frontend acceda a la respuesta

## Ventajas de esta solución

1. No requiere configuración especial en el frontend
2. Permite solicitudes directas desde el frontend al backend
3. Es más cercana a la configuración que necesitarías en producción
4. Evita la complejidad de configurar y mantener un proxy

## Para producción

En un entorno de producción, se recomienda:

1. Limitar Access-Control-Allow-Origin a dominios específicos en lugar de usar '*'
2. Implementar medidas de seguridad adicionales como tokens CSRF
3. Considerar el uso de servicios o middlewares CORS proporcionados por el framework del backend
