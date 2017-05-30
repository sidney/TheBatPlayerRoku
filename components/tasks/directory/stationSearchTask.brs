sub search()
    print "Searching for " + m.top.query

    query = urlencode(m.top.query)
    url = GetConfig().BatUtils + "jsonSearch?search=" + query

    Request = GetRequest()
    Request.SetUrl(url)
    jsonString = Request.GetToString()
    searchResults = ParseJSON(jsonString)

    stationsContentNode = createObject("RoSGNode","ContentNode")
    
    for each station in searchResults 
        item = createObject("roSGNode", "SingleStationContentNode")
        item.title = station.name
        item.name = station.name
        item.image = station.image
        item.url = station.stream
        item.playlist = station.playlist
        ' item.streamformat = station.format
        
        if item.image = invalid OR item.image = ""
            encodedSearch = item.title.EncodeUri()
            item.image = GetConfig().BatUtils + "imageSearch?query=" + encodedSearch + "&display=true"
        end if

        if station.codec = "audio/aacp"
            item.streamformat = "es.aac-adts"
        end if

        stationsContentNode.appendChild(item)

    end for

    m.top.stations = stationsContentNode
end sub

sub GetPort() as Dynamic
    return invalid
end sub