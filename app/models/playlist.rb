class Playlist < ApplicationRecord
  before_create { |playlist| playlist.id = SecureRandom.uuid }

  belongs_to :owner, class_name: 'User'

  def merges
    return Merge.where(left: self).or(Merge.where(right: self))
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

  has_many :left_merges,
           class_name: 'Merge',
           foreign_key: 'left_id',
           inverse_of: :left,
           dependent: :delete_all
  has_many :right_merges,
           class_name: 'Merge',
           foreign_key: 'right_id',
           inverse_of: :right,
           dependent: :delete_all
end
