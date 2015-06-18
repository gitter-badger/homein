class PlacesController < ApplicationController
  before_action :set_place, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!, only: [:edit, :update, :destroy, :create, :new]
  before_action :authorize_user, only: [:edit, :update, :destroy]

  # GET /places
  # GET /places.json
  def index
    @places = Place.all
  end

  # GET /places/1
  # GET /places/1.json
  def show
  end

  # GET /places/new
  def new
    @place = Place.new
  end

  # GET /places/1/edit
  def edit
  end

  # POST /places
  # POST /places.json
  def create
    @place = Place.new(place_params)

    @place.user = current_user 

    respond_to do |format|
      if @place.save
        format.html { redirect_to @place, notice: 'Place was successfully created.' }
        format.json { render :show, status: :created, location: @place }
      else
        format.html { render :new }
        format.json { render json: @place.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /places/1
  # PATCH/PUT /places/1.json
  def update
    respond_to do |format|
      if @place.update(place_params)
        format.html { redirect_to @place, notice: 'Place was successfully updated.' }
        format.json { render :show, status: :ok, location: @place }
      else
        format.html { render :edit }
        format.json { render json: @place.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /places/1
  # DELETE /places/1.json
  def destroy
    @place.destroy
    respond_to do |format|
      format.html { redirect_to places_url, notice: 'Place was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  def search
      search = Place.search do 
          if params[:query]
            fulltext params[:query]
          else 
            if params[:description]
              keywords params[:description], :fields => [:description]
            end 
            if params[:address]
              keywords params[:address], :fields => [:address]
            end 

            with(:rooms).greater_than_or_equal_to(params[:rooms].to_i)
            with(:bathrooms).greater_than_or_equal_to(params[:bathrooms].to_i)
            with(:available).equal_to(params[:available])
            
            if params[:price].to_i > 0
                with(:price).less_than_or_equal_to(params[:price].to_i)
            end
          end 
      end 

      @places = search.results
      
      render 'index' 
  end 

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_place
      @place = Place.find(params[:id])
    end

    def authorize_user 
      if @place.user != current_user
        flash.alert = "You're not authorized to do that!"

        redirect_to root_path
      end 
    end 

    # Never trust parameters from the scary internet, only allow the white list through.
    def place_params
      params.require(:place).permit(:description, :address, :latitude, :longitude, :rooms, :bathrooms, :available, :price, :contact)
    end
end
