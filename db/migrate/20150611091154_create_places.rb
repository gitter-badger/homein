class CreatePlaces < ActiveRecord::Migration
  def change
    create_table :places do |t|
      t.string  :description
      t.string  :address
      t.float   :latitude
      t.float   :longitude
      t.integer :rooms
      t.integer :bathrooms
      t.boolean :available
      t.integer :price
      t.string  :contact
      t.attachment :picture 

      t.timestamps null: false
    end
  end
end
