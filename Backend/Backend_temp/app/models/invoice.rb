class Invoice < ApplicationRecord
  has_one :payment_complement
  validates :uuid, :customer, :issue_date, :subtotal, :total, presence: true
end
