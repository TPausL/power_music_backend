class Playlist < ApplicationRecord
  before_save { |playlist| playlist.id = SecureRandom.uuid }

  belongs_to :owner, class_name: 'User'
end
