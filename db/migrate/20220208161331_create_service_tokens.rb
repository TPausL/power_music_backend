class CreateServiceTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :service_tokens, id: false do |t|
      t.string :id, primary_key: true, null: false
      t.string :access_token, null: false
      t.string :refresh_token, null: false
      t.string :scope, null: false
      t.integer :expires_in, null: false
      t.string :source, null: false
      t.string :client_id
      t.string :client_secret
      t.references :owner, type: :string
      t.timestamps
    end

    add_foreign_key :service_tokens, :users, column: :owner_id
  end
end
