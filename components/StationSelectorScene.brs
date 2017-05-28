' Saved/My stations
sub getMyStations()
    m.getMyStationsTask = createObject("roSGNode", "GetStationsTask")
    m.getMyStationsTask.observeField("stations", "myStationsUpdated")
    m.getMyStationsTask.control = "RUN"
end sub

sub myStationsUpdated(event)
    stations = event.getData()
    m.content.insertChild(stations, 2)
    m.myStations = stations
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
    m.featuredStations = stations
    print stations
end sub