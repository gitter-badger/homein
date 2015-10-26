---
---
String.prototype.capitalizeFirstLetter = () -> 
    this.charAt(0).toUpperCase() + this.slice(1)

delay = do ->
        timer = 0
        (callback, ms) ->
            clearTimeout timer
            timer = setTimeout(callback, ms)
            return
            
window.destroyNotification = () ->
    delay (->
        $("#notification-box").html("")
        return
    ), 5000

$(document).ready ->
    ApplicationID = '3J0AVN6KSY'
    
    SearchOnlyApiKey = 'fde549a36ac77931bd57966851982602'
    
    client = algoliasearch(ApplicationID, SearchOnlyApiKey)
    
    index = client.initIndex('homein_places_development')
    
    map = ""
    markers = []
    markerClusterer = ""
    bounds = new google.maps.LatLngBounds()
    geocoder = new google.maps.Geocoder()
    infoWindow = new google.maps.InfoWindow
    currentQuery = "*"
    currentNumericFilters = {}
    place_for = ""
    
    currentContent = "" 
    
    initializeMap = () ->
        center = new google.maps.LatLng(33.9874177, -18.5969899)
        
        mapOptions = 
            zoom: 3  # I want to be able to see everything. I'll figure out how to auto zoom to see all markers later 
        
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
            $("#searchbar").blur()
            return 
        ), 500
        
        return 
    
    decodeURL = () ->
        # First, figure out where you are 
        if /^\/(homein)?\/?$/.test(location.pathname) # Are you on the index?
            # Capture the facets in the location hash 
            facetsregex = /(\&|\#)((((bathrooms)|(rooms)|(price))=\d+(-\d+)?)|(for=(rent|sale)))/ig 
            if facetsregex.test(location.hash)
                userfacets = location.hash.match(facetsregex)
                
                facets = {}
                
                for facet of userfacets
                    facetname = userfacets[facet].substr(1).split("=")[0]
                    facetvalues = [userfacets[facet].substr(1).split("=")[1].split("-")[0], userfacets[facet].substr(1).split("=")[1].split("-")[1]]
                    
                    if facetname != "for"
                        currentNumericFilters[facetname] = facetvalues 
                    else 
                        place_for = facetvalues[0]
            
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
                numericFilters: numericFilters,
                facetFilters: "for:#{decodeURIComponent(place_for)}"
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
        facets_stats = {}
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
                    
                for facet of content.facets_stats 
                    facets_stats[facet] = {
                        "max": Math.max.apply(Math, Object.keys(content.facets[facet])),
                        "min": Math.min.apply(Math, Object.keys(content.facets[facet]))
                    }

                numericFilters = {}
                
                for facet of facets_stats
                    numericFilters[facet] = [ facets_stats[facet].min, facets_stats[facet].max ]

                if /(\&|\#)((bathrooms)|(rooms)|(price))=\d+(-\d+)?/ig.test(location.hash)
                    for filter of currentNumericFilters
                        numericFilters[filter] = [ currentNumericFilters[filter][0], currentNumericFilters[filter][1] ]

                for facet of numericFilters
                    facets_html += 
                        "<div class=\"facet\" id=\"#{facet}\">
                            #{facet.capitalizeFirstLetter()}: "
                            
                    if facet == "price" 
                        facets_html += "$"
                            
                    facets_html += 
                            "<input type=\"number\" step=\"1\" class=\"minimum\" min=\"#{facets_stats[facet]["min"]}\" max=\"#{facets_stats[facet]["max"]}\" value=\"#{parseInt(numericFilters[facet][0])}\">
                            
                            <div class=\"slider\" data-facet=\"#{facet}\" data-min=\"#{facets_stats[facet]["min"]}\" data-max=\"#{facets_stats[facet]["max"]}\"></div>"
                    
                    if facet == "price"
                        facets_html += "$"
                    
                    facets_html += 
                            "<input type=\"number\" step=\"1\" class=\"maximum\" min=\"#{facets_stats[facet]["min"]}\" max=\"#{facets_stats[facet]["max"]}\" value=\"#{parseInt(numericFilters[facet][1])}\">
                        </div>"
                    
                facets_html += 
                    "<div class=\"facet\" id=\"for\">
                        For: 
                        
                        <select id=\"place_for\" class=\"facet_input\">
                            <option value=\" \">All</option>"
                            
                for option in Object.keys(content.facets["for"])
                    facets_html += "<option value=\"#{option}\""
                    
                    if option == place_for 
                        facets_html += " selected=\"selected\""
                    
                    facets_html += ">#{option}</option>"
                    
                facets_html += 
                        "</select>
                    </div>"

                facets_container.html(facets_html)
                
                $("#facets-container .slider").slider
                    range: true,
                    create: () ->
                        $(this).slider( "option", "min", $(this).data("min") )
                        $(this).slider( "option", "max", $(this).data("max") )
                        $(this).slider( "option", "values", [ numericFilters[$(this).data("facet")][0], numericFilters[$(this).data("facet")][1] ] )
                    stop: (event, ui) ->
                        facet = ui.handle.parentElement.parentElement.id 
                        
                        values = ui.values
                        
                        encodeURL(facet, values)
                        
                        decodeURL()
                    slide: (event, ui) ->
                        facet = $(this).data("facet") 
                        
                        $("##{facet} .minimum").val(ui.values[0])
                        $("##{facet} .maximum").val(ui.values[1])
                
                $(".facet_input").change () ->
                    facet = this.parentElement.id 
                    
                    if facet != "for"
                        values = [ parseInt(this.parentElement.firstElementChild.value), parseInt(this.parentElement.firstElementChild.nextElementSibling.value) ]
                    else 
                        values = [ this.value ]
                        place_for = this.value 
                    
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
                "<h1><a href=\"##{location.hash.substr(1)}\" onclick=\"$('#notification-box').html('This preview will not show you individual places yet!'); destroyNotification();\">#{hits[hit].address}</a></h1>
                <p>#{hits[hit].description.replace(/\n/, "<br />")}</p>
                <p>Rooms: #{hits[hit].rooms} Bathrooms: #{hits[hit].bathrooms}</p>
                <p>Price: $#{hits[hit].price}"
                
                if hits[hit].for == "Rent"
                    content += " per month"
                
                content += "</p>"
                
                if /^\/(places)\/\d+\/?$/.test(location.pathname)
                    i = 0
                    while i < image_urls.length
                        content += "<a href='" + image_urls[i] + "' target='_blank'><img src='" + image_thumb_urls[i] + "' /></a>"
                        i++
                
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
    
    showIntroduction = () ->
        alert "Welcome to homein!\n
            This is just a preview, where you can play around with the facets to understand what homein does.\n
            The places you see here aren't actually for sale or rent. They're just placeholders.\n
            If you happen not to see anything here then I've probably cleared the development database for some reason or another. More stuff will appear here eventually once I can start working again."
    
    if /first_load=1/.test(document.cookie)
        null 
    else 
        showIntroduction()
        document.cookie = "first_load=1"