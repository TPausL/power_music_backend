class CreatePlaylists < ActiveRecord::Migration[7.0]
  def change
    create_table :playlists, id: false do |t|
      t.string :id, primary_key: true, null: false
      t.references :owner, type: :string
      t.string :title
      t.string :source
      t.string :source_id
      t.integer :count
      t.string :image_url
      t.timestamps
    end
    add_foreign_key :playlists, :users, column: :owner_id
  end
end
