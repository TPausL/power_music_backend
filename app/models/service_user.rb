class ServiceUser < ApplicationRecord
  belongs_to :user

  def to_builder
    Jbuilder.new do |user|
      user.name name
      user.email email
      user.image image_url
    end
  end
end
