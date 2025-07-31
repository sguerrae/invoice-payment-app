import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './globals.css' // Importamos los estilos globales
import App from './App.jsx'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
