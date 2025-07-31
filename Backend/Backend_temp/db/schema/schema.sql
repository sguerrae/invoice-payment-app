-- This file is auto-generated from the current state of the database. Instead
-- of editing this file, please use the migrations feature of Active Record to
-- incrementally modify your database, and then regenerate this schema definition.
--
-- This file is the source Rails uses to define your schema when running `bin/rails
-- db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
-- be faster and is potentially less error prone than running all of your
-- migrations from scratch. Old migrations may fail to apply correctly if those
-- migrations use external dependencies or application code.
--
-- It's strongly recommended that you check this file into your version control system.

CREATE TABLE IF NOT EXISTS schema_migrations (
    version character varying NOT NULL,
    CONSTRAINT schema_migrations_pkey PRIMARY KEY (version)
);

CREATE TABLE IF NOT EXISTS ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) NOT NULL,
    updated_at timestamp(6) NOT NULL,
    CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key)
);

CREATE TABLE IF NOT EXISTS invoices (
    id bigserial NOT NULL,
    uuid character varying NOT NULL,
    customer character varying NOT NULL,
    issue_date date NOT NULL,
    subtotal numeric(12,2) NOT NULL,
    total numeric(12,2) NOT NULL,
    paid boolean DEFAULT false,
    created_at timestamp(6) NOT NULL,
    updated_at timestamp(6) NOT NULL,
    CONSTRAINT invoices_pkey PRIMARY KEY (id)
);

CREATE INDEX IF NOT EXISTS index_invoices_on_uuid ON invoices USING btree (uuid);
ALTER TABLE invoices ADD CONSTRAINT unique_uuid UNIQUE (uuid);

CREATE TABLE IF NOT EXISTS payment_complements (
    id bigserial NOT NULL,
    invoice_id bigint NOT NULL,
    facturama_id character varying NOT NULL,
    pdf_url character varying,
    xml_url character varying,
    created_at timestamp(6) NOT NULL,
    updated_at timestamp(6) NOT NULL,
    CONSTRAINT payment_complements_pkey PRIMARY KEY (id)
);

CREATE INDEX IF NOT EXISTS index_payment_complements_on_invoice_id ON payment_complements USING btree (invoice_id);
ALTER TABLE payment_complements ADD CONSTRAINT fk_rails_invoice_payment_complements FOREIGN KEY (invoice_id) REFERENCES invoices(id);

INSERT INTO schema_migrations (version) VALUES
('20250729120000'),
('20250729120100');
