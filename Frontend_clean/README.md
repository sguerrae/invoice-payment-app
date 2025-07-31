# Xenon Challenge: Invoice Payment App

## Author
**Said Jair Guerra Escudero**  
Senior Full Stack Developer

---

## 🧠 Description
This app helps Xenon Industrial Articles to upload, visualize, and reconcile PPD invoices and generate payment complements using Facturama's API.

---

## 🛠️ Tech Stack

### Frontend
- React + Vite with HMR and ESLint
- Tailwind CSS for styling
- ShadCN UI for component library

### Plugins
- [@vitejs/plugin-react](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react) uses [Babel](https://babeljs.io/) for Fast Refresh
- [@vitejs/plugin-react-swc](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react-swc) uses [SWC](https://swc.rs/) for Fast Refresh

---

## 🚀 Project Structure

- `Frontend/`: React + Tailwind + ShadCN UI
- `Backend/`: Ruby on Rails API-only app

---

## 📦 Requirements

### Backend

- Ruby 3.2+
- Rails 7+
- PostgreSQL or SQLite (development)

### Frontend

- Node 18+
- Vite

---

## ▶️ How to Run

### Backend

```bash
cd Backend
bundle install
rails db:create db:migrate
rails s
```

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
