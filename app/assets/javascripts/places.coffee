# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

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
    
    renderPlaces = (places) ->
        places_container.empty()
        
        places_html = "" 
        
        for place in places 
            places_html += 
                "<a href='/places/" + place.id + "'><h3>" + place.address + "</a>" +
                "<p>" + place.description + "</p>" + 
                "<p>Price: $" + place.price + "</p>"
                
        places_container.html(places_html)
    
    prepareFacets = (facets) ->
        queryFacets = ""
        for facet of facets 
            queryFacets += facet + ":" + facets[facet] + ", "
            
        queryFacets
        
    renderFacets = (facets) ->
        facets_container.empty()
        
        facets_html = ""
        
        for facet of facets
            facets_html += 
                "<h4>" + facet + ":</h4> " + 
                "<ul>"
                
            values = facets[facet]
                
            for value of values
                facets_html += "<li><a href='#' data-value='" + value + "' data-facet='" + facet + "'>" + value + "</a></li>"
                
            facets_html += "</ul>"
                
        facets_container.html(facets_html)
        
        $("#facets-container ul li a").on 'click', ->
            facets_container.empty()
            places_container.empty()
            
            currentfacet = []
            
            currentfacet.push this.getAttribute('data-facet')
            currentfacet.push this.getAttribute('data-value')
            
            if currentfacets[currentfacet[0]]
                delete currentfacets[currentfacet[0]]
            else 
                currentfacets[currentfacet[0]] = currentfacet[1]
            
            facet = this.getAttribute('data-facet') + ":" + this.getAttribute('data-value')
            
            search(searchbar.val(), prepareFacets(currentfacets))
    
    setURLParams = (query, facet) ->
        urlParams = "#"
        urlParams += "q=" + encodeURIComponent(query)
        console.log urlParams
    
    search = (query, facetfilters) ->
        index.search(query, 
        {
            facets: "*"
            facetFilters: facetfilters 
        },
        (err, content) ->
            if err 
                console.error(err)
            else
                renderPlaces(content.hits)
                renderFacets(content.facets)
            )
    
    search('', '')
    
    searchbar.keyup ->
        search(searchbar.val(), prepareFacets(currentfacets))
        setURLParams(searchbar.val())