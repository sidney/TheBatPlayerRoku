Sub RunUserInterface(aa as Object)
    'DeleteRegistry()
    InitFonts()
    SetTheme()
    'DownloadDefaultStationsIfNeeded()
    
    'print "------ Starting web server ------"
    StartServerWithPort(GetPort())

    InitBatPlayer()
    showChannelSGScreen()
End Sub

Sub showChannelSGScreen()
  screen = CreateObject("roSGScreen")
  m.global = screen.getGlobalNode()
  GetGlobalAA().global = m.global

  m.global.addField("audio", "node", false)
  m.global.addField("station", "node", false)
  m.global.addField("song", "node", false)
  m.global.addField("panelSet", "node", false)

  screen.setMessagePort(GetPort())
  m.scene = screen.CreateScene("RootPanelSet")

  screen.show()
  m.global.ObserveField("station", GetPort())

  StartEventLoop()
End Sub

Sub stationChanged(station)
    print "stationChanged(station)"
    GetNowPlayingScreen()
    Get_Metadata(station, GetPort())
End Sub

Sub trackChanged(track)
    print "Main#trackChanged()"

    'GetGlobalAA().global.song = track
    GetGlobalAA().track = track
    
    nowPlayingScreen = GetNowPlayingScreen()
    nowPlayingScreen.RefreshNowPlayingScreen()
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