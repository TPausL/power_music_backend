class ServiceToken < ApplicationRecord
  before_create { |token| token.id = SecureRandom.uuid }

  belongs_to :owner, class_name: 'User'
end
