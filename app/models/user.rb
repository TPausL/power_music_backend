class User < ApplicationRecord
  before_save { |user| user.id = SecureRandom.uuid }

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :validatable

  has_many :access_grants,
           class_name: 'Doorkeeper::AccessGrant',
           foreign_key: :resource_owner_id,
           dependent: :delete_all # or :destroy if you need callbacks

  has_many :access_tokens,
           class_name: 'Doorkeeper::AccessToken',
           foreign_key: :resource_owner_id,
           dependent: :delete_all # or :destroy if you need callbacks

  has_many :service_tokens,
           class_name: 'ServiceToken',
           foreign_key: :owner_id,
           dependent: :delete_all # or :destroy if you need callbacks

  has_many :service_connections,
           class_name: 'ServiceUser',
           dependent: :delete_all

  has_many :playlists,
           class_name: 'Playlist',
           foreign_key: :owner_id,
           dependent: :delete_all

  has_many :merges,
           class_name: 'Merge',
           foreign_key: :owner_id,
           dependent: :delete_all

  def spotify_playlists
    return self.playlists&.where(source: 'spotify')
  end
  def youtube_playlists
    return self.playlists&.where(source: 'youtube')
  end

  def spotify_token
    return self.service_tokens&.where(source: 'spotify')&.first
  end
  def youtube_token
    return self.service_tokens&.where(source: 'youtube')&.first
  end

  def spotify_user
    return self.service_connections&.where(source: 'spotify')&.first
  end
  def youtube_user
    return self.service_connections&.where(source: 'youtube')&.first
  end

  validates :name, presence: true
end
