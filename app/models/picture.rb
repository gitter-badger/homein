class Picture < ActiveRecord::Base
    belongs_to :place 
    
    has_attached_file :image, :default_url => ":rails_root/public/system/:class/:attachment/missing.png"
	
	validates_with AttachmentPresenceValidator, attributes: :image 
	validates_with AttachmentSizeValidator, attributes: :image, less_than: 1.megabytes, :message => "Images should be smaller than 1MB"
	validates_with AttachmentContentTypeValidator, attributes: :image, :content_type => [ "image/jpeg", "image/png" ], :message => "JPEG or PNG files only, please!"
end
