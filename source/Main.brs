Sub RunUserInterface(aa as Object)
    'DeleteRegistry()
    InitFonts()
    SetTheme()
    'DownloadDefaultStationsIfNeeded()
    '
    'GetGlobalAA().IsStationSelectorDisplayed = true

    'print "------ Starting web server ------"
    StartServerWithPort(GetPort())

    'GetStationSelectionHeader()

    'ListStations()
    InitBatPlayer()

    showChannelSGScreen()
    'StartEventLoop()
End Sub

Sub showChannelSGScreen()
  screen = CreateObject("roSGScreen")
  m.global = screen.getGlobalNode()
  GetGlobalAA().global = m.global

  m.global.addField("audio", "node", false)
  m.global.addField("station", "node", false)
  m.global.addField("song", "node", false)
  'm.global.addField("metadataTask", "node", false)
  m.global.addField("displayNowPlayingScreen", "bool", false)

  screen.setMessagePort(GetPort())
  m.scene = screen.CreateScene("RowListExample")

  screen.show()
  m.global.ObserveField("displayNowPlayingScreen", GetPort())
  m.global.ObserveField("station", GetPort())
  'm.global.ObserveField("song", GetPort())

  metadataTask = createObject("roSGNode", "fetchStationMetadataTask")
  metadataTask.ObserveField("track", GetPort())
  metadataTask.control = "WAIT"

  GetGlobalAA().metadataTask = metadataTask

  StartEventLoop()
End Sub

Sub stationChanged(station)
    print "stationChanged()"
    startFetchingMetadata(GetGlobalAA().station)
End Sub

Sub trackChanged(track)
    print "Main#trackChanged()"
    GetGlobalAA().track = track
    nowPlayingScreen = GetNowPlayingScreen()
    nowPlayingScreen.RefreshNowPlayingScreen()

    print m.global
End Sub

Sub startFetchingMetadata(station)
    print "startFetchingMetadata()"

    task = GetGlobalAA().metadataTask
    task.station = station
    task.control = "RUN"    
End Sub

Function InitBatPlayer()
    'BumpOrResetSavedDirectoryCacheValue()

	'GetGlobalAA().lastSongTitle = ""
    'Analytics = GetSession().Analytics
    'Analytics.AddEvent("Application Launched")

    ' print "------ Initializing LastFM ------"
    ' InitLastFM()
    ' print "------ Initializing fonts ------"
End Function


Function DownloadDefaultStationsIfNeeded()
    storedStations = RegRead("stations", "batplayer")
    if storedStations = invalid
        print "------ Downloading Default Stations ------"
        url = GetConfig().BatUtils + "defaultStations"
        SyncGetFile(url, "tmp:/stations.json", true)
    end if
End Function