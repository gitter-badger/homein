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
    
    map = ""
    infoWindow = new google.maps.InfoWindow
    currentQuery = "*"
    currentNumericFilters = ""
    currentHits = ""
    
    currentContent = "" 
    
    initializeMap = () ->
        center = new google.maps.LatLng(6.802066748199674, -58.16407062167349)
        
        mapOptions = 
            zoom: 14  # I want to be able to see everything. I'll figure out how to auto zoom to see all markers later 
            center: center
        
        map = new google.maps.Map(document.getElementById('map-canvas'), mapOptions)
        
    decodeURL = () ->
        # First, figure out where you are 
        if /^\/(places)?\/?$/.test(location.pathname) # Are you on the index?
            # Capture the facets in the location hash 
            facetsregex = /(\&|\#)((bathrooms)|(rooms)|(price))=\d+(-\d+)?/ig 
            if facetsregex.test(location.hash)
                userfacets = location.hash.match(facetsregex)
                
                facets = {}
                
                for facet of userfacets
                    facetname = userfacets[facet].substr(1).split("=")[0]
                    facetvalues = [userfacets[facet].substr(1).split("=")[1].split("-")[0], userfacets[facet].substr(1).split("=")[1].split("-")[1]]
                    
                    facets[facetname] = facetvalues 
            
            search()
            return 
        else if /^\/(places)\/\d+\/?(edit)?\/?$/.test(location.pathname) # Are you on the show or edit views?
            numericFilterRegex = /\/\d+(?=\/$)?/g
            
            currentNumericFilters = "id=" + location.pathname.match(numericFilterRegex)[0].substr(1)
            
            search()
            
            return 
        else if /^\/(places)\/(new)\/?$/.test(location.pathname) # Are you on the new view?
            center = new google.maps.LatLng(6.802066748199674, -58.16407062167349)
            
            marker = new google.maps.Marker 
                position: center 
                map: map 
                title: 'New place'
                draggable: true 
                
            infoWindow.setContent(form)
            infoWindow.open map, marker
    
    search = () ->
        # Check values of parameters, otherwise return default values 
        query = currentQuery
        numericFilters = currentNumericFilters
    
        index.search(
            query, 
            {
                facets: "*"
                numericFilters: numericFilters
            },
            (err, content) ->
                if err 
                    console.error err 
                    return
                    
                currentContent = content 
                
                placeMarkers()
        )
        
    placeMarkers = () ->
        markers = []
        hits = currentContent.hits 
        
        for hit of hits  
            position = new google.maps.LatLng(hits[hit].latitude, hits[hit].longitude)
            address = hits[hit].address
            
            content = 
                "<h1><a href='/places/" + hits[hit].objectID + "'>" + hits[hit].address + "</a></h1>" + 
                "<p>" + hits[hit].description.replace(/\n/, "<br />") + "</p>" + 
                "<p>Rooms: " + hits[hit].rooms + " Bathrooms: " + hits[hit].bathrooms + "</p>" + 
                "<p>Price: $" + hits[hit].price + "</p>"
            
            markers.push  new google.maps.Marker 
                position: position
                map: map 
                title: address
                draggable: false 
                id: hit
                content: content 
                
            google.maps.event.addListener markers[hit], 'click', ->
                infoWindow.setContent(this.content)
                infoWindow.open map, this
        
        if hits.length == 1 
            infoWindow.setContent(markers[0].content)
            infoWindow.open map, markers[0]
    
    initializeMap()
    decodeURL()