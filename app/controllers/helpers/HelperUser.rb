class Helpers::HelperUser
  attr_accessor :name
  attr_accessor :email
  attr_accessor :id
  attr_accessor :image_url

  def initialize(data)
    @name = data['display_name']
    @email = data['email']
    @id = data['id']
    @image_url = data['images'].first['url']
  end
end
