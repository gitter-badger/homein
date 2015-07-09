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
    
    index = client.initIndex('Place')
    
    # DOM initialization
    places_container = $("#places-container")
    searchbar = $("#searchbar")
    facets_container = $("#facets-container")
    
    currentfacets = {}
    currentquery = ""
    currentcontent = ""
    
    renderPlaces = (places) ->
        places_container.empty()
        
        places_html = "" 
        
        for place in places 
            places_html += 
                "<a href='/places/" + place.id + "'><h3>" + place.address + "</a>" +
                "<p>" + place.description + "</p>" + 
                "<p>Price: $" + place.price + "</p>"
                
        places_container.html(places_html)
    
    prepareFacets = (facets, url) ->
        if url 
            queryFacets = ""
            for facet of facets 
                queryFacets += "&" + facet + "=" + facets[facet][0] + "-" + facets[facet][1]
        else 
            queryFacets = []
            for facet of facets 
                queryFacets.push facet + ">=" + facets[facet][0]
                queryFacets.push facet + "<=" + facets[facet][1]
        
        queryFacets
        
    setURLParams = (query, facets) ->
        urlParams = "#"
        urlParams += "q=" + encodeURIComponent(searchbar.val())
        urlParams += prepareFacets(facets, true)
        
        location.replace urlParams
        
    decodeURLParams = () ->
        urlParams = decodeURIComponent(location.hash)
        
        if urlParams.split("&")[0].split("=")[1]
            query = urlParams.split("&")[0].split("=")[1]
        else 
            query = ""
        
        qfacets = urlParams.split("&").splice(1)
        
        facets = {}
        
        for facet in qfacets 
            facets[facet.split("=")[0]] = [facet.split("=")[1].split("-")[0], facet.split("=")[1].split("-")[1]]
        
        currentfacets = facets 
        
        currentquery = query 
        searchbar.val(query)
        
    renderFacets = (facets) ->
        facets_container.empty()
        
        facets_html = ""
        
        for facet of facets
            if facet == 'price'
                facets_html += 
                    "<p id='" + facet + "'>" + facet.capitalizeFirstLetter() + ": $" + currentcontent['facets_stats'][facet]['min'] + " - $" + currentcontent['facets_stats'][facet]['max'] + "</p>
                    <div data-facet='" + facet + "'
                    data-max='" + currentcontent['facets_stats'][facet]['max'] + "'
                    data-min='" + currentcontent['facets_stats'][facet]['min'] + "'
                    ></div>"
            else
                facets_html += 
                    "<p id='" + facet + "'>" + facet.capitalizeFirstLetter() + ": " + currentcontent['facets_stats'][facet]['min'] + " - " + currentcontent['facets_stats'][facet]['max'] + "</p>
                    <div data-facet='" + facet + "'
                    data-max='" + currentcontent['facets_stats'][facet]['max'] + "'
                    data-min='" + currentcontent['facets_stats'][facet]['min'] + "'
                    ></div>"
                
        facets_container.html(facets_html)
        
        $("#facets-container div").slider 
            range: true
            create: () ->
                $(this).slider( "option", "min", $(this).data('min') )
                $(this).slider( "option", "max", $(this).data('max') )
                $(this).slider( "option", "values", [$(this).data('min'), $(this).data('max')] )
            stop: (event, ui) ->
                label = $(ui.handle.parentNode.previousElementSibling)
                if label[0].id == 'price'
                    label.html(label[0].id.capitalizeFirstLetter() + ": $" + ui.values[0] + " - $" + ui.values[1])
                else 
                    label.html(label[0].id.capitalizeFirstLetter() + ": " + ui.values[0] + " - " + ui.values[1])
                    
                currentfacets[label[0].id] = [ui.values[0], ui.values[1]]
                
                setURLParams(currentquery, currentfacets)
                search(currentquery, prepareFacets(currentfacets))
    
    search = (query, facetfilters) ->
        index.search(query, 
        {
            facets: "*"
            numericFilters: facetfilters 
        },
        (err, content) ->
            if err 
                console.error(err)
            else
                currentcontent = content 
                
                renderPlaces(content.hits)
                renderFacets(content.facets)
            )
    
    decodeURLParams()
    
    search(currentquery, prepareFacets(currentfacets))
    
    searchbar.keyup ->
        setURLParams(searchbar.val(), currentfacets)
        search(searchbar.val(), prepareFacets(currentfacets))