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
    
    places = ""
    
    search = (query) ->
        index.search(query, (err, content) ->
            if err 
                console.log(err)
            else
                places = content.hits
                
                places_html = ""
                
                #Render the places
                for place in places 
                    places_html += 
                        "<a href='/places/" + place.id + "'><h3>" + place.address + "</a>" +
                        "<p>" + place.description + "</p>" + 
                        "<p>Price: $" + place.price + "</p>"
                
                places_container.html(places_html)
            )
    
    search('')
    
    searchbar.keyup ->
        search(searchbar.val())