sub setupStations()
    getFeaturedStations()
    getLongtailStations()
    getDashStations()
    getSOMAFMStations()
    getGabeStations()
end sub

function rowItemSelected(event)
	currentItemLocation = event.getData()
	currentRow = currentItemLocation[0]
    currentItem = currentItemLocation[1]
    
	rowData = m.rowlist.content.getChild(currentRow)

    if rowData = invalid
        return false
    end if

	station = rowData.getChild(currentItem)
    showStationPlayDialog(station)
end function

' Featured Stations
sub getFeaturedStations()
    url = GetConfig().BatUtils + "featured"

    m.getFeaturedStationsTask = createObject("roSGNode", "GetDirectoryStationsTask")
    m.getFeaturedStationsTask.url =  url
    m.getFeaturedStationsTask.title = "Selected Featured Stations"
    m.getFeaturedStationsTask.observeField("stations", "longtailStationsUpdated")
    m.getFeaturedStationsTask.control = "RUN"
end sub

sub featuredStationsUpdated(event)
    stations = event.getData()
    m.content.insertChild(stations, 0)
end sub



' Longtail Stations
sub getLongtailStations()
    m.getLongtailStationsTask = createObject("roSGNode", "GetDirectoryStationsTask")
    m.getLongtailStationsTask.url =  "https://longtail.fm/api/external/stations"
    m.getLongtailStationsTask.title = "Stations from Longtail Music"
    m.getLongtailStationsTask.observeField("stations", "longtailStationsUpdated")
    m.getLongtailStationsTask.control = "RUN"
end sub

sub longtailStationsUpdated(event)
    stations = event.getData()
    m.content.insertChild(stations, 2)
end sub



' Dash Stations
sub getDashStations()
    url = GetConfig().BatUtils + "dashradio"

    m.getDashStationsTask = createObject("roSGNode", "GetDirectoryStationsTask")
    m.getDashStationsTask.url =  url
    m.getDashStationsTask.title = "Stations from Dash Radio"
    m.getDashStationsTask.observeField("stations", "longtailStationsUpdated")
    m.getDashStationsTask.control = "RUN"
end sub

sub dashStationsUpdated(event)
    stations = event.getData()
    m.content.insertChild(stations, 1)
end sub


' SOMA FM Stations
function getSOMAFMStations()
    url = GetConfig().BatUtils + "somafm"

    m.somaFMStationsTask = createObject("roSGNode", "GetDirectoryStationsTask")
    m.somaFMStationsTask.url =  url
    m.somaFMStationsTask.title = "Stations from SOMA FM"
    m.somaFMStationsTask.observeField("stations", "somaStationsUpdated")
    m.somaFMStationsTask.control = "RUN"
end function

funtion somaStationsUpdated()
    stations = event.getData()
    m.content.insertChild(stations, 3)
end function


' Gabe Stations
sub getGabeStations()
    url = GetConfig().BatUtils + "gabeFavorites"

    m.getGabeStationsTask = createObject("roSGNode", "GetDirectoryStationsTask")
    m.getGabeStationsTask.url =  url
    m.getGabeStationsTask.title = "Some of Gabe's Current Favorites"
    m.getGabeStationsTask.observeField("stations", "longtailStationsUpdated")
    m.getGabeStationsTask.control = "RUN"
end sub

sub gabeStationsUpdated(event)
    stations = event.getData()
    m.content.insertChild(stations, 4)
end sub