class Place < ActiveRecord::Base
	belongs_to :user
	has_many :pictures 
	
	include AlgoliaSearch
	
	algoliasearch index_name: "homein_places", per_environment: true do 
	    attributesForFaceting [:rooms, :bathrooms, :price]
	end 
end
