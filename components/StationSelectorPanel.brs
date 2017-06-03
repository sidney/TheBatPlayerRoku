sub setupStations()
    getMyStations()
    getLongtailStations()
    getFeaturedStations()

    setupDirectoryButtons()
end sub

' Saved/My stations
sub getMyStations()
    m.getMyStationsTask = createObject("roSGNode", "GetStationsTask")
    m.getMyStationsTask.observeField("stations", "myStationsUpdated")
    m.getMyStationsTask.control = "RUN"
end sub

sub myStationsUpdated(event)
    stations = event.getData()
    m.content.insertChild(stations, 0)
end sub

' Longtail Stations
sub getLongtailStations()
    print "getLongtailStations()"

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

' Featured stations
sub getFeaturedStations()
    print "getFeaturedStations()"
    m.getFeaturedStationsTask = createObject("roSGNode", "GetDirectoryStationsTask")
    m.getFeaturedStationsTask.url = "https://batutils.thebatplayer.fm/featured"
    m.getFeaturedStationsTask.title = "Featured Stations"
    m.getFeaturedStationsTask.observeField("stations", "featuredStationsUpdated")
    m.getFeaturedStationsTask.control = "RUN"
end sub

sub featuredStationsUpdated(event)
    stations = event.getData()
    m.content.insertChild(stations, 1)
end sub

sub navigateToBrowse()
    print "navigateToBrowse()"

    m.categoryList = m.top.createChild("FeaturedStationsPanel")

    m.top.getParent().getParent().getParent().panelSet.appendChild(m.categoryList)
end sub

function navigateToFeaturedStations()
    m.featuredStationsPanel = m.top.createChild("FeaturedStationsPanel")
    m.top.getParent().getParent().getParent().panelSet.appendChild(m.featuredStationsPanel)
end function
