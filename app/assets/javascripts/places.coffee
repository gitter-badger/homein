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
    markers = []
    markerClusterer = ""
    bounds = new google.maps.LatLngBounds()
    geocoder = new google.maps.Geocoder()
    infoWindow = new google.maps.InfoWindow
    currentQuery = "*"
    currentNumericFilters = {}
    
    currentContent = "" 
    
    initializeMap = () ->
        center = new google.maps.LatLng(6.802066748199674, -58.16407062167349)
        
        mapOptions = 
            zoom: 14  # I want to be able to see everything. I'll figure out how to auto zoom to see all markers later 
            center: center
        
        map = new google.maps.Map(document.getElementById('map-canvas'), mapOptions)
    
    delay = do ->
        timer = 0
        (callback, ms) ->
            clearTimeout timer
            timer = setTimeout(callback, ms)
            return
    
    $("#searchbar").keyup ->
        value = [ this.value ]
        
        encodeURL("q", value)
        
        delay (->
            decodeURL()
            return 
        ), 500
        return 
    
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
                    
                    currentNumericFilters[facetname] = facetvalues 
            
            if /(q=)(\w+)&?/.test(location.hash)
                currentQuery = location.hash.match(/(q=)(\w+)&?/)[2]
            else 
                currentQuery = "*"
            
            search()
            renderFacets()
            return 
        else if /^\/(places)\/\d+\/?(edit)?\/?$/.test(location.pathname) # Are you on the show or edit views?
            numericFilterRegex = /\/\d+(?=\/$)?/g
            
            currentNumericFilters["id"] = [location.pathname.match(numericFilterRegex)[0].substr(1), location.pathname.match(numericFilterRegex)[0].substr(1)] # Not ideal, but it works
            
            search()
            
            return 
        else if /^\/(places)\/(new)\/?$/.test(location.pathname) # Are you on the new view?
            placeMarkers()
        else if /currentuser/.test(location.pathname)
            currentNumericFilters["user_id"] = [currentuser, currentuser]
            
            search()
            
            return 
    
    encodeURL = (item, item_values) ->
        string = location.hash
        value_string = "" 
        
        if item_values.length > 1 
            value_string += item_values[0] + "-" + item_values[1]
        else if item_values.length == 1
            value_string += item_values[0]
        
        if RegExp("(#|&)" + item, 'i').test(decodeURIComponent(location.hash))
            regex = RegExp("(#|&)(" + item + ")=(((\\d+)(-(\\d+))?)|(\\w|%20)*)", "i")
            string = string.replace(regex, "$1$2=" + encodeURIComponent(value_string))
            
            location.replace(string)
        else
            if /#/.test(location.hash)
                string = location.hash + "&" + item + "=" + value_string
            else 
                string = "#" + item + "=" + value_string
                
            location.replace(string)
    
    search = () ->
        # Check values of parameters, otherwise return default values 
        query = currentQuery
        numericFilters = []
        for filter of currentNumericFilters
            numericFilters.push(filter + ">=" + currentNumericFilters[filter][0])
            numericFilters.push(filter + "<=" + currentNumericFilters[filter][1])
    
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

    renderFacets = () -> # Back again!
        facets_container = $("#facets-container")
        facets_html = ""

        # First do an empty search to get the max and min values for each facet 
        index.search(
            "",
            {
                facets: "*"
            },
            (err, content) ->
                if err 
                    console.error err 
                    return 

                facets_stats = content.facets_stats 

                numericFilters = {}
                
                for facet of facets_stats
                    numericFilters[facet] = [ facets_stats[facet].min, facets_stats[facet].max ]

                if /(\&|\#)((bathrooms)|(rooms)|(price))=\d+(-\d+)?/ig.test(location.hash)
                    for filter of currentNumericFilters
                        numericFilters[filter] = [ currentNumericFilters[filter][0], currentNumericFilters[filter][1] ]

                for facet of numericFilters
                    if facet == 'price'
                        facets_html += 
                            "<p id='" + facet + "'>" + facet.capitalizeFirstLetter() + ": $<input type='number' class='facet_input' value='" + numericFilters[facet][0] + "' min='" + facets_stats[facet]['min'] + "' max='" + facets_stats[facet]['max'] + "' /> - $<input type='number' class='facet_input' value='" + numericFilters[facet][1] + "' min='" + facets_stats[facet]['min'] + "' max='" + facets_stats[facet]['max'] + "' /></p>" + 
                            "<div data-facet='" + facet + "' 
                                data-max='" + facets_stats[facet]['max'] + "' 
                                data-min='" + facets_stats[facet]['min'] + "'
                            ></div>"
                    else 
                        facets_html +=
                            "<p id='" + facet + "'>" + facet.capitalizeFirstLetter() + ": <input type='number' class='facet_input' value='" + numericFilters[facet][0] + "' min='" + facets_stats[facet]['min'] + "' max='" + facets_stats[facet]['max'] + "' /> - <input type='number' class='facet_input' value='" + numericFilters[facet][1] + "' min='" + facets_stats[facet]['min'] + "' max='" + facets_stats[facet]['max'] + "' /></p>" + 
                            "<div data-facet='" + facet + "' 
                                data-max='" + facets_stats[facet]['max'] + "' 
                                data-min='" + facets_stats[facet]['min'] + "'
                            ></div>"

                facets_container.html(facets_html)
                
                $("#facets-container div").slider
                    range: true
                    create: () ->
                        $(this).slider( "option", "min", $(this).data("min") )
                        $(this).slider( "option", "max", $(this).data("max") )
                        $(this).slider( "option", "values", [ numericFilters[$(this).data("facet")][0], numericFilters[$(this).data("facet")][1] ] )
                    stop: (event, ui) ->
                        facet = ui.handle.parentElement.previousSibling.id 
                        values = ui.values
                        
                        encodeURL(facet, values)
                        decodeURL()
                    slide: (event, ui) ->
                        ui.handle.parentElement.previousSibling.firstElementChild.value = ui.values[0]
                        ui.handle.parentElement.previousSibling.firstElementChild.nextElementSibling.value = ui.values[1]
                        
                $(".facet_input").change () ->
                    facet = this.parentElement.id 
                    values = [ parseInt(this.parentElement.firstElementChild.value), parseInt(this.parentElement.firstElementChild.nextElementSibling.value) ]
                    
                    encodeURL(facet, values)
                    decodeURL()
            )
        
    placeMarkers = () ->
        if markers.length > 0 
            for marker in markers 
                marker.setMap(null)
                
            markerClusterer.clearMarkers()
        
        markers = []
        
        hits = currentContent.hits 
        
        if /^\/(places)\/(new)\/?$/.test(location.pathname)
            hits = [1]
        
        for hit of hits  
            position = new google.maps.LatLng(hits[hit].latitude, hits[hit].longitude)
            address = hits[hit].address
            
            if /^\/(places)\/\d+\/?(edit)\/?$/.test(location.pathname)
                markers.push new google.maps.Marker 
                    position: position
                    map: map 
                    title: 'Edit place'
                    draggable: true 
                    content: form
                    
                bounds.extend(position)
            else if /^\/(places)\/(new)\/?$/.test(location.pathname)
                position = new google.maps.LatLng(6.802066748199674, -58.16407062167349)
            
                markers.push new google.maps.Marker 
                    position: position 
                    map: map 
                    title: 'New place'
                    draggable: true 
                    content: form
                    
                bounds.extend(position)
            else 
                content = 
                "<h1><a href='/places/" + hits[hit].objectID + "'>" + hits[hit].address + "</a></h1>" + 
                "<p>" + hits[hit].description.replace(/\n/, "<br />") + "</p>" + 
                "<p>Rooms: " + hits[hit].rooms + " Bathrooms: " + hits[hit].bathrooms + "</p>" + 
                "<p>Price: $" + hits[hit].price + "</p>"
                
                if /^\/(places)\/\d+\/?$/.test(location.pathname)
                    i = 0
                    while i < image_urls.length
                        content += "<a href='" + image_urls[i] + "' target='_blank'><img src='" + image_thumb_urls[i] + "' /></a>"
                        i++
                        
                content += "<br>"
                
                if typeof currentuser != 'undefined'
                    if hits[hit].user_id == currentuser
                        content += "<a href='/places/" + hits[hit].id + "/edit' class=\"place-management-link\"><i class=\"fa fa-pencil\"></i>
                        </a>" + 
                        "<a data-confirm='Are you sure you want to delete this place?' rel='nofollow' data-method='delete' href='/places/" + hits[hit].id + "' class=\"place-management-link\"><i class=\"fa fa-trash-o\"></i></a>"
                
                markers.push  new google.maps.Marker 
                    position: position
                    map: map 
                    title: address
                    draggable: false 
                    id: hit
                    content: content 
                    
                bounds.extend(position)
                    
            google.maps.event.addListener markers[hit], 'click', ->
                infoWindow.setContent(this.content)
                infoWindow.open map, this
        
        markerClusterer = new MarkerClusterer(map, markers)
        
        map.fitBounds(bounds)
        map.panToBounds(bounds)
        
        if hits.length == 1
            if /^\/(places)\/(new)\/?$/.test(location.pathname) or /^\/(places)\/\d+\/(edit)\/?$/.test(location.pathname)
                google.maps.event.addListener(markers[0], 'dragend', setLatLng)
        
            infoWindow.setContent(markers[0].content)
            infoWindow.open map, markers[0]
            
    setLatLng = () ->
        $("form .field #place_latitude").val(this.position.lat())
        $("form .field #place_longitude").val(this.position.lng())
        
        map.panTo(this.position)
        
        reverseGeocode(this.position)
        
    reverseGeocode = (position) ->
        geocoder.geocode( { 'latLng' : position }, (results, status) ->
            $("form .field #place_address").val(results[0].formatted_address)
            )
    
    $("#toggle-filter-button").click () -> 
        $("#facets-container").toggle()
    
    initializeMap()
    decodeURL()