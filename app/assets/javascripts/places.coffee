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
                
                if !/^\/(places)?\/?$/.test(location.pathname)
                    i = 0
                    while i < image_urls.length
                        content += "<a href='" + image_urls[i] + "' target='_blank'><img src='" + image_thumb_urls[i] + "' /></a>"
                        i++
                        
                content += "<br>"
                
                if typeof currentuser != 'undefined'
                    if hits[hit].user_id == currentuser
                        content += "<a href='/places/" + hits[hit].id + "/edit'><svg class='svg-icon' viewBox='0 0 20 20'><path d='M18.303,4.742l-1.454-1.455c-0.171-0.171-0.475-0.171-0.646,0l-3.061,3.064H2.019c-0.251,0-0.457,0.205-0.457,0.456v9.578c0,0.251,0.206,0.456,0.457,0.456h13.683c0.252,0,0.457-0.205,0.457-0.456V7.533l2.144-2.146C18.481,5.208,18.483,4.917,18.303,4.742 M15.258,15.929H2.476V7.263h9.754L9.695,9.792c-0.057,0.057-0.101,0.13-0.119,0.212L9.18,11.36h-3.98c-0.251,0-0.457,0.205-0.457,0.456c0,0.253,0.205,0.456,0.457,0.456h4.336c0.023,0,0.899,0.02,1.498-0.127c0.312-0.077,0.55-0.137,0.55-0.137c0.08-0.018,0.155-0.059,0.212-0.118l3.463-3.443V15.929z M11.241,11.156l-1.078,0.267l0.267-1.076l6.097-6.091l0.808,0.808L11.241,11.156z'></path></svg>
                        </a>" + 
                        "<a data-confirm='Are you sure?' rel='nofollow' data-method='delete' href='/places/" + hits[hit].id + "'><svg class='svg-icon' viewBox='0 0 20 20'><path d='M17.114,3.923h-4.589V2.427c0-0.252-0.207-0.459-0.46-0.459H7.935c-0.252,0-0.459,0.207-0.459,0.459v1.496h-4.59c-0.252,0-0.459,0.205-0.459,0.459c0,0.252,0.207,0.459,0.459,0.459h1.51v12.732c0,0.252,0.207,0.459,0.459,0.459h10.29c0.254,0,0.459-0.207,0.459-0.459V4.841h1.511c0.252,0,0.459-0.207,0.459-0.459C17.573,4.127,17.366,3.923,17.114,3.923M8.394,2.886h3.214v0.918H8.394V2.886z M14.686,17.114H5.314V4.841h9.372V17.114z M12.525,7.306v7.344c0,0.252-0.207,0.459-0.46,0.459s-0.458-0.207-0.458-0.459V7.306c0-0.254,0.205-0.459,0.458-0.459S12.525,7.051,12.525,7.306M8.394,7.306v7.344c0,0.252-0.207,0.459-0.459,0.459s-0.459-0.207-0.459-0.459V7.306c0-0.254,0.207-0.459,0.459-0.459S8.394,7.051,8.394,7.306'></path></svg></a>"
                
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
    
    initializeMap()
    decodeURL()