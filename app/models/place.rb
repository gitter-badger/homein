class Place < ActiveRecord::Base
	belongs_to :user
	
	searchable do
	    text :description, :address
	    
	    boolean :available
	    integer :rooms
	    integer :bathrooms
	    integer :price
	end 
end
