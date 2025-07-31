class PaymentComplement < ApplicationRecord
  belongs_to :invoice
  validates :facturama_id, presence: true
end
