class AddIndexToMerges < ActiveRecord::Migration[7.0]
  def change
    add_index :merges, %i[left_id right_id], unique: true
  end
end
