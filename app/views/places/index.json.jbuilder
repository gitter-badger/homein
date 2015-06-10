json.array!(@places) do |place|
  json.extract! place, :id, :description, :latitude, :longitude, :price, :rooms, :bathrooms, :available, :contact
  json.url place_url(place, format: :json)
end
