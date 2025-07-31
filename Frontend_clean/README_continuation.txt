
### Frontend

```bash
cd Frontend
npm install
npm run dev
```

---

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the backend directory with:

```
FACTURAMA_API_KEY=your_api_key
FACTURAMA_SECRET=your_api_secret
```

---

## 📝 Features

- XML invoice upload and validation
- Invoice visualization with status indicators
- Payment complement generation via Facturama
- Download of generated PDFs and XMLs

---

## 🌐 API Endpoints

- `GET /invoices`: List all invoices
- `POST /invoices`: Upload new invoice XML
- `POST /payment_complements`: Generate payment complement
- `GET /payment_complements/:id/pdf`: Download PDF
- `GET /payment_complements/:id/xml`: Download XML

---

## 📋 Development Notes

Check the CORS_SOLUTION.md file for details on how Cross-Origin issues were addressed for local development.
