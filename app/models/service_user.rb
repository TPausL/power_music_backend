class ServiceUser < ApplicationRecord
  belongs_to :user

  def to_builder
    Jbuilder.new do |user|
      user.(self, :name, :email)
      user.image image_url
      user.service source
    end
  end
end
