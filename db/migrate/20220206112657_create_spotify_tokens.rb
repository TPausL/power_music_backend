class CreateSpotifyTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :spotify_tokens, id: false do |t|
      t.string :id, primary_key: true, null: false
      t.string :access_token, null: false
      t.string :refresh_token, null: false
      t.string :scope, null: false
      t.integer :expires_in, null: false
      t.references :owner, type: :string
      t.timestamps
    end

    add_foreign_key :spotify_tokens, :users, column: :owner_id
  end
end
