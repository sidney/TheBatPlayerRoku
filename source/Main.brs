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
  m.global.addField("metadataTask", "node", false)
  m.global.addField("displayNowPlayingScreen", "bool", false)

  screen.setMessagePort(GetPort())
  m.scene = screen.CreateScene("RowListExample")

  screen.show()
  m.global.ObserveField("displayNowPlayingScreen", GetPort())
  m.global.ObserveField("station", GetPort())
  'm.global.ObserveField("song", GetPort())

  m.global.metadataTask = createObject("roSGNode", "fetchStationMetadataTask")
  m.global.metadataTask.ObserveField("track", GetPort())

  StartEventLoop()
End Sub

Sub stationChanged(station)
    print "stationChanged()"
    startFetchingMetadata(GetGlobalAA().station)
    'UpdateScreen()
End Sub

Sub trackChanged(track)
    print "trackChanged()"
    GetGlobalAA().track = track
    'print "m.scene.closeWaitingDialog = true"
    m.scene.closeWaitingDialog = true
    UpdateScreen()
End Sub

Sub startFetchingMetadata(station)
    print "startFetchingMetadata()"

    task = m.global.metadataTask
    task.station = station
    task.control = "RUN"    
End Sub

Sub showNowPlayingScreen()
    print "showNowPlayingScreen!!!"
End Sub

Function InitBatPlayer()
    'BumpOrResetSavedDirectoryCacheValue()

	GetGlobalAA().lastSongTitle = ""
    Analytics = GetSession().Analytics
    Analytics.AddEvent("Application Launched")

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