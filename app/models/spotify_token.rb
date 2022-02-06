class SpotifyToken < ApplicationRecord
  before_save { |token| token.id = SecureRandom.uuid }

  belongs_to :owner, class_name: 'User'
end
