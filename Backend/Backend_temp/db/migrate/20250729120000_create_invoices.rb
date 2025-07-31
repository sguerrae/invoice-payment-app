class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.string :uuid, null: false
      t.string :customer, null: false
      t.date :issue_date, null: false
      t.decimal :subtotal, precision: 12, scale: 2, null: false
      t.decimal :total, precision: 12, scale: 2, null: false
      t.boolean :paid, default: false
      t.timestamps
    end
    add_index :invoices, :uuid, unique: true
  end
end
