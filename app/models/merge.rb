class Merge < ApplicationRecord
  before_save { |user| user.id = SecureRandom.uuid }

  belongs_to :owner, class_name: 'User'

  belongs_to :left, class_name: 'Playlist'
  belongs_to :right, class_name: 'Playlist'

  def to_builder
    Jbuilder.new do |m|
      m.id id
      m.left left.to_builder
      m.right right.to_builder
      m.direction direction
      m.name name
    end
  end

  def self.execute
    Merge.all.each do |m|
      owner = m.owner
      helper = Helpers::MergeHelper.new(owner)
      should_merge = false
      if (m.direction == 'both' || m.direction == 'left')
        r_length = helper.get_playlist_length(m.right)
        should_merge = true if (r_length != m.right.count)
      end
      if (m.direction == 'both' || m.direction == 'right')
        l_length = helper.get_playlist_length(m.left)
        should_merge = true if (l_length != m.left.count)
      end
    end
  end

  validates :owner, :left, :right, presence: true
end
