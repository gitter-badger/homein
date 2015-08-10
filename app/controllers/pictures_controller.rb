class PicturesController < ApplicationController
    before_action :set_place
    before_action :authenticate_user!
    before_action :authorize_user
    
    def destroy
        @picture = Picture.find(params[:id])
        
        @picture.destroy
        respond_to do |format|
          format.html { redirect_to :back, notice: 'Picture was sucessfully deleted.' }
          format.json { head :no_content }
        end
    end
    
    private 
        def set_place
            @picture = Picture.find(params[:id])
        end
        
        def authorize_user 
            if @picture.place.user != current_user
                flash.alert = "You're not authorized to do that!"
                
                redirect_to root_path
            end 
        end 
end
