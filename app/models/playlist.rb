class Playlist < ApplicationRecord
  before_save { |playlist| playlist.id = SecureRandom.uuid }

  belongs_to :owner, class_name: 'User'

  def merges
    return left_merges.merge right_merges
  end

  def to_builder
    Jbuilder.new do |m|
      m.id id
      m.title title
      m.source source
      m.count count
    end
  end

  private

  has_many :left_merges, class_name: 'Merge', foreign_key: 'left_id'
  has_many :right_merges, class_name: 'Merge', foreign_key: 'right_id'
end
