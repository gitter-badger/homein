class CreatePlaces < ActiveRecord::Migration
  def change
    create_table :places do |t|
      t.string :description
      t.float :latitude
      t.float :longitude
      t.integer :price
      t.integer :rooms
      t.integer :bathrooms
      t.boolean :available
      t.string :contact

      t.timestamps null: false
    end
  end
end
