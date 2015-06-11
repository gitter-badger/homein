json.array!(@places) do |place|
  json.extract! place, :id, :description, :address, :latitude, :longitude, :rooms, :bathrooms, :available, :price, :contact
  json.url place_url(place, format: :json)
end
