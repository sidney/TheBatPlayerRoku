Sub HandleSaveRequestForStations(request as Object)
	data = GetDataFromRequest(request)
	data = urlunescape(data)

	print "Saving Data: " + data
	RegWrite("stations", data, "batplayer")

	if GetGlobalAA().IsStationSelectorDisplayed = true
		RefreshStationScreen()
	end if

End Sub

Sub HandleSaveRequestForLights(request as Object)
	data = GetDataFromRequest(request)
	data = urlunescape(data)
	RegWrite("lights", data, "batplayer")
End Sub

Sub HandleSaveRequestForLightIp(request as Object)
	data = GetDataFromRequest(request)
	RegWrite("lightip", data, "batplayer")

	lightData = ParseJSON(data)
	if lightData <> invalid AND lightData.DoesExist("brightness")
		brightness = lightData.brightness
		GetSession().Brightness.DefaultMinimum = brightness[0]
		GetSession().Brightness.DefaultMaximum = brightness[1]
	end if
End Sub

Sub HandleSaveRequestForLastFM(request as Object)
	print "Running HandleSaveRequestForLastFM"

	data = GetDataFromRequest(request)
	data = urlunescape(data)

	RegWrite("lastfmData", data, "batplayer")
	print "saved data: " + data
End Sub

Sub GetLastFMData(returnAsJson as Boolean) as Object
	lastfmData = RegRead("lastfmData", "batplayer")

	if lastfmData = invalid then
		lastfmData = "[]"
	end if

	if returnAsJson then
		return lastfmData
	end if

	if lastfmData <> invalid then
		lastfmData = ParseJSON(lastfmData)
		return lastfmData
	end if

End Sub

Sub GetStations() as Object
	json = GetStationsJson()
	stationsArray = ParseJSON(json)

	if json <> invalid then
    	stationsArray = ParseJSON(json)
    end if

	if stationsArray = invalid then
		json = ReadAsciiFile("pkg:/data/stations.json")
	    stationsArray = ParseJSON(json)
	 end if

	return stationsArray
End Sub

Sub GetNowPlayingJson(returnAsJson as Boolean) as string
	NowPlayingScreen = GetGlobalAA().Lookup("NowPlayingScreen")
	if NowPlayingScreen <> invalid AND NowPlayingScreen.DoesExist("song") AND NowPlayingScreen.song <> invalid then
		song = NowPlayingScreen.song
		if song.DoesExist("ArtistImageDownloadTimer") then song.Delete("ArtistImageDownloadTimer")
		if song.DoesExist("BackgroundImageDownloadTimer") then song.Delete("BackgroundImageDownloadTimer")
		return FormatJson(song)
	else
		return FormatJson(CreateObject("roAssociativeArray"))
	end if
End Sub

Sub GetStationsJson() as string
	json = RegRead("stations", "batplayer")

	if json = invalid then
		print "Invalid stations json"
		json = ReadAsciiFile("pkg:/data/stations.json")
	end if

	return json
End Sub

Sub GetDataFromRequest(request as Object) as string
	print "Running GetDataFrom"
	questionMark = Instr(0, request.uri, "?data=")
	data = Mid(request.uri, questionMark + 6)
	print data
	return data
End Sub
