# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

# Add a method to the string prototype to capitalize the first letter of a String
# SO surprised javascript doesn't already have this 
String.prototype.capitalizeFirstLetter = () -> 
    this.charAt(0).toUpperCase() + this.slice(1)

$(document).ready ->
    ApplicationID = '3J0AVN6KSY'
    
    SearchOnlyApiKey = 'fde549a36ac77931bd57966851982602'
    
    client = algoliasearch(ApplicationID, SearchOnlyApiKey)
    
    index = client.initIndex('homein_places_' + window.environment)
    
    infoWindow = new google.maps.InfoWindow
    
    initializeMap = (center, zoom, bounds, callback) ->
        map = new google.maps.Map(document.getElementById('map-canvas'), 
            zoom: zoom
            center: center 
        )
        
        if bounds 
            map.fitBounds(bounds)
            map.panToBounds(bounds)
            
        callback(map)
    
    search = (query, facetFilters, numericFilters, callback) ->
        index.search(
            query, 
            {
                "numericFilters": numericFilters
                "facetFilters": facetFilters
            },
            (err, content) ->
                if err 
                    alert err 
                    return
                
                callback(content)
        )
    
    getQuery = () ->
        query = ""
        
        queryRegex = /(?:&|#)query=(\w+)(?=&)?/g 
        
        queryMatch = queryRegex.exec(location.hash)
        
        if queryMatch
            query = queryMatch[1]
        
        return query 
        
    getFacetFilters = () ->
        facetFilters = []
        
        facetFiltersRegex = /(?:&|#)(for)=(sale|rent)(?=&)?/g
        
        facetFiltersMatch = facetFiltersRegex.exec(location.hash)
        
        while facetFiltersMatch != null 
            facetFilters.push facetFiltersMatch[1] + ":" + facetFiltersMatch[2]
            facetFiltersMatch = facetFiltersRegex.exec(location.hash)
            
        return facetFilters
    
    getNumericFilters = () ->
        numericFilters = []
            
        numericFiltersRegex = /(?:&|#)(bathrooms|rooms|price)=((?:\d+)(?:-\d+)?)(?=&)?/g;
        
        numericFiltersMatch = numericFiltersRegex.exec(location.hash)
        
        while numericFiltersMatch != null 
            console.log numericFiltersMatch[2]
            if /-/.test(numericFiltersMatch[2])
                numericFilters.push numericFiltersMatch[1] + ":" + numericFiltersMatch[2].replace("-", " to ")
            else 
                numericFilters.push numericFiltersMatch[1] + "=" + numericFiltersMatch[2]
            
            numericFiltersMatch = numericFiltersRegex.exec(location.hash)
    
    getContent = (result) ->
        content = 
            "<h1><a href=\"/places/#{result.objectID}/\">#{result.address}</a></h1>
            <p>#{result.description.replace(/\n/, "<br />")}</p>
            <p>Rooms: #{result.rooms} Bathrooms: #{result.bathrooms}</p>
            <p>Price: $#{result.price}"
            
        if result.for == "Rent"
            content += " per month"
        
        content += "</p>"
        
        if typeof currentuser != 'undefined' && currentuser == result.user_id
            content += 
                "<a href=\"/places/#{result.objectID}/edit\" class=\"place-management-link\"><i class=\"fa fa-pencil\" title=\"Edit place\"></i></a>
                <a data-confirm=\"Are you sure you want to delete this place?\" rel=\"nofollow\" data-method=\"delete\" href=\"/places/#{result.objectID}\" class=\"place-management-link\"><i class=\"fa fa-trash-o\" title=\"Delete place\"></i></a>"
                
        
        return content 
    
    decodeURL = () ->
        if /^\/(places)?\/?$/.test(location.pathname)
            search(getQuery(), getFacetFilters(), getNumericFilters(), (content) ->
                bounds = new google.maps.LatLngBounds()
                
                markers = []
                
                results = content.hits 
                
                for result in results 
                    position = new google.maps.LatLng(result.latitude, result.longitude)
                    
                    bounds.extend(position)
                
                center = bounds.getCenter()
                initializeMap(center, 1, bounds, (map) ->  #Set an arbitrary zoom level to initialize the map, then zoom, pan to bounds 
                    for result in results 
                        console.log result 
                        position = new google.maps.LatLng(result.latitude, result.longitude)
                        
                        marker = new google.maps.Marker 
                            position: position 
                            map: map 
                            draggable: false 
                            content: getContent(result)
                            title: result.description 
                            
                        marker.addListener('click', () ->
                            infoWindow.setContent(this.content)
                            infoWindow.open(map, this) 
                        )
                            
                        markers.push marker 
                    
                    markerClusterer = new MarkerClusterer(map, markers)
                )
            )
            
    decodeURL()