class Helpers::Song
  attr_accessor :name, :artists
  def initialize(name, artists = '')
    @name = name
    @artists = artists
  end
end
