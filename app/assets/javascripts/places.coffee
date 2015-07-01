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
    
    places = ""
    facets = ""
    
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
                places = content.hits
                facets = content.facets
                places_html = ""
                facets_html = ""
                
                #Render the places
                for place in places 
                    places_html += 
                        "<a href='/places/" + place.id + "'><h3>" + place.address + "</a>" +
                        "<p>" + place.description + "</p>" + 
                        "<p>Price: $" + place.price + "</p>"
                
                places_container.html(places_html)
                #/Render the places
                
                #Render the facets
                for facet of facets
                    facets_html += 
                        "<h4>" + facet + ":</h4> " + 
                        "<ul>"
                        
                    values = facets[facet]
                        
                    for value of values
                        facets_html += "<li><a href='#' data-value='" + value + "' data-facet='" + facet + "'>" + value + "</a></li>"
                        
                    facets_html += "</ul>"
                        
                facets_container.html(facets_html)
                #/Render the facets
                
                $("#facets-container ul li a").on 'click', ->
                    facets_container.empty()
                    places_container.empty()
                    
                    console.log this.getAttribute('data-value')
                    search(searchbar.val(), this.getAttribute('data-facet') + ":" + this.getAttribute('data-value'))
            )
    
    search('', '')
    
    searchbar.keyup ->
        search(searchbar.val())