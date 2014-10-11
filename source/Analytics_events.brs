Function Analytics_TrackChanged(artistName as string, trackName as string, stationName as string)
	if artistname <> invalid AND trackname <> invalid AND stationName <> invalid AND isnonemptystr(artistName) AND isnonemptystr(trackName)
		Analytics = GetSession().Analytics

		properties = CreateObject("roAssociativeArray")
		properties.artistName = artistName
		properties.trackName = trackName
		properties.stationName = stationName
		Analytics.AddEvent("Track Changed", properties)
	end if
End Function

Function Analytics_StationSelected(stationName as string, url as string)
	if isnonemptystr(stationName) AND isnonemptystr(url)
		Analytics = GetSession().Analytics
		
		properties = CreateObject("roAssociativeArray")
		properties.stationName = stationName
		properties.stationStream = url
		Analytics.AddEvent("Station Selected", properties)
	end if
End Function

Function BatLog(logMessage as string, logType = "message" as string, properties = invalid as Object)
	print "****" + logMessage

	if properties = invalid
		properties = CreateObject("roAssociativeArray")
	end if
	properties.type = logType
	
	NowPlayingScreen = GetNowPlayingScreen()
	if NowPlayingScreen <> invalid
		properties.song = NowPlayingScreen.song
	end if
	
	Analytics = GetSession().Analytics
	Analytics.AddEvent("Log", properties)
End Function