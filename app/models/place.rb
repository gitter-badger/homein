class Place < ActiveRecord::Base
	belongs_to :user
	
	def self.maxmins 
	    minmaxes = {}
	    
	    minmaxes['price'] = [Place.order(:price).first.price, Place.order(:price).last.price]
	    minmaxes['rooms'] = [Place.order(:rooms).first.rooms, Place.order(:rooms).last.rooms]
	    minmaxes['bathrooms'] = [Place.order(:bathrooms).first.bathrooms, Place.order(:bathrooms).last.bathrooms]
	    
	    minmaxes
	end 
	
	include AlgoliaSearch
	
	algoliasearch do 
	    attributesForFaceting [:rooms, :bathrooms, :price]
	end 
end
