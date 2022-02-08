class CreateServiceUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :service_users, id: false do |t|
      t.string :id, primary_key: true, null: false
      t.string :email, null: false
      t.string :name
      t.string :image_url
      t.string :source, null: false
      t.references :user, type: :string
      t.timestamps
    end
    add_foreign_key :service_users, :users
  end
end
