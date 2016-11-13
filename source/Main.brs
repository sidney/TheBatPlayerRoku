Sub RunUserInterface(aa as Object)
    'DeleteRegistry()
    SetTheme()
    DownloadDefaultStationsIfNeeded()

    GetGlobalAA().IsStationSelectorDisplayed = true

    print "------ Starting web server ------"
    StartServerWithPort(GetPort())

    GetStationSelectionHeader()

    print "------ Listing stations ------"
    ListStations()
    InitBatPlayer()
    print "------ Starting Loop ------"
    StartEventLoop()
End Sub

Function InitBatPlayer()
    BumpOrResetSavedDirectoryCacheValue()

	GetGlobalAA().lastSongTitle = ""
    Analytics = GetSession().Analytics
    Analytics.AddEvent("Application Launched")

    print "------ Initializing LastFM ------"
    InitLastFM()
    print "------ Initializing fonts ------"
    InitFonts()
End Function


Function DownloadDefaultStationsIfNeeded()
    storedStations = RegRead("stations", "batplayer")
    if storedStations = invalid
        print "------ Downloading Default Stations ------"
        url = GetConfig().BatUtils + "defaultStations"
        SyncGetFile(url, "tmp:/stations.json", true)
    end if
End Function