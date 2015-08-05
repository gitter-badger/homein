class Place < ActiveRecord::Base
	belongs_to :user
	
	has_attached_file :picture, :styles => { :medium => "300x300>", :thumb => "100x100>" }, :default_url => ":rails_root/public/system/:class/:attachment/missing.png"
	validates_attachment_content_type :picture, :content_type => /\Aimage\/.*\Z/
	
	include AlgoliaSearch
	
	algoliasearch index_name: "homein_places", per_environment: true do 
	    attributesForFaceting [:rooms, :bathrooms, :price]
	end 
end
