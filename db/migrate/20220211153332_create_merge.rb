class CreateMerge < ActiveRecord::Migration[7.0]
  def change
    drop_table :merges
    create_table :merges, id: false do |t|
      t.string :id, primary_key: true, null: false
      t.references :owner, type: :string
      t.references :left, null: false, type: :string
      t.references :right, null: false, type: :string
      t.string :direction, null: false, default: 'both'
      t.string :name
      t.timestamps
    end
    add_foreign_key :merges, :users, column: :owner_id
    add_foreign_key :merges, :playlists, column: :left_id
    add_foreign_key :merges, :playlists, column: :right_id
  end
end
