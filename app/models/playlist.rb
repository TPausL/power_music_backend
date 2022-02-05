class Playlist < ApplicationRecord
    before_save { |playlist| playlist.id = SecureRandom.uuid }
end
