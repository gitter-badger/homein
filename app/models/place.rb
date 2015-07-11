class Place < ActiveRecord::Base
	belongs_to :user
	
	include AlgoliaSearch
	
	algoliasearch do 
	    attributesForFaceting [:rooms, :bathrooms, :price]
	end 
end
