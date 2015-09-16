class Picture < ActiveRecord::Base
    belongs_to :place 
    
    has_attached_file :image, :default_url => ":rails_root/public/system/:class/:attachment/missing.png"
	validates_attachment_content_type :image, :content_type => /\Aimage\/.*\Z/
end
