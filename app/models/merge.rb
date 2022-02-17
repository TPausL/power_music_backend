class Merge < ApplicationRecord
  before_create { |merge| merge.id = SecureRandom.uuid }

  belongs_to :owner, class_name: 'User'

  belongs_to :left, class_name: 'Playlist', inverse_of: :left_merges
  belongs_to :right, class_name: 'Playlist', inverse_of: :right_merges

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
    Merge.all.each { |m| self.exec_one(m) }
  end

  def self.exec_one(m)
    owner = m.owner
    helper = Helpers::MergeHelper.new(owner)
    should_merge = false
    if (m.direction == 'both' || m.direction == 'left')
      r_length = helper.playlist_length(m.right)
      should_merge = true if (r_length != m.right.count)
    end
    if (m.direction == 'both' || m.direction == 'right')
      l_length = helper.playlist_length(m.left)
      should_merge = true if (l_length != m.left.count)
    end
    if (should_merge)
      if (m.direction == 'left')
        source_songs = helper.playlist_songs(m.right)
        helper.add_songs(source_songs, m.left)
      end
      if (m.direction == 'right')
        source_songs = helper.playlist_songs(m.left)
        helper.add_songs(source_songs, m.right)
      end
      if (m.direction == 'both')
        left_songs = helper.playlist_songs(m.left)
        right_songs = helper.playlist_songs(m.right)
        helper.add_songs(left_songs, m.right)
        helper.add_songs(right_songs, m.left)
      end
    end
  end

  validates :owner, :left, :right, presence: true
end
