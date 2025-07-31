class CreatePaymentComplements < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_complements do |t|
      t.references :invoice, null: false, foreign_key: true
      t.string :facturama_id, null: false
      t.string :pdf_url
      t.string :xml_url
      t.timestamps
    end
  end
end
