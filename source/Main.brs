Sub RunUserInterface(aa as Object)
    'DeleteRegistry()
    print "------ Starting web server ------"
    StartServerWithPort(GetPort())
    print "------ Listing stations ------"
    GetStationSelectionHeader()
    ListStations()
    InitBatPlayer()
    print "------ Starting Loop ------"
    StartEventLoop()
End Sub

Function InitBatPlayer()
	GetGlobalAA().lastSongTitle = ""
    Analytics = GetSession().Analytics
    Analytics.AddEvent("Application Launched")

    print "------ Finding Rdio Playlist ------"
    FindRdioPlaylist()
    print "------ Initializing LastFM ------"
    InitLastFM()
    print "------ Initializing fonts ------"
    InitFonts()

End Function
