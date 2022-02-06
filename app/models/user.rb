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

  has_one :spotify_access_token,
          class_name: 'SpotifyToken',
          foreign_key: :owner_id,
          dependent: :delete # or :destroy if you need callbacks

  validates :name, presence: true
end
