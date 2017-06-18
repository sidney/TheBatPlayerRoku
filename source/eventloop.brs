REM Global event loop

Sub HandleWebEvent (msg as Object)
    server = GetGlobalAA().lookup("WebServer")

		if server <> invalid
	    server.prewait()
	    tm = type(msg)
	    if tm="roSocketEvent" or msg=invalid
	        server.postwait()
	    end if
	 else
	end if
End Sub


Sub HandleNowPlayingScreenEvent (msg as Object)
  if type(msg) = "roUniversalControlEvent" AND GetGlobalAA().IsStationSelectorDisplayed <> true
    Audio = GetGlobalAA().AudioPlayer

	key = msg.GetInt()

	  if key = 3 then
	  	ToggleBrightnessMode("up")

	  else if key = 2 then
	  	ToggleBrightnessMode("down")

	  else if key = 10 then
	  	ToggleLastFMAccounts()

	  else if key = 0 then
	    'Exit
		NowPlayingScreen = GetNowPlayingScreen()
		NowPlayingScreen.screen = invalid
      	NowPlayingScreen = invalid
      	GetGlobalAA().SavedNowPlayingScreen = invalid

    '   StationSelectionScreen = GetGlobalAA().StationSelectionScreen
    '   StationSelectionScreen.RefreshNowPlayingData()

      GetGlobalAA().lastSongTitle = invalid
			GetGlobalAA().IsStationSelectorDisplayed = true

	  else if key = 106
			' Display help message
			DisplayHelpPopup()
	  end if

  end if

End Sub

Sub HandleTimers()
	station = GetGlobalAA().station
	track = GetGlobalAA().track
	NowPlayingScreen = GetGlobalAA().SavedNowPlayingScreen
	Session = GetSession()

	'LastFM Scrobbles should take place even if the
	'now playing screen is not displayed.
	' if NowPlayingScreen.scrobbleTimer <> invalid THEN
	' 	if NowPlayingScreen.scrobbleTimer.totalSeconds() >= 15 then
	' 		if track.Artist <> invalid and track.Title <> invalid
	' 			NowPlayingScreen.scrobbleTimer = invalid
	' 			ScrobbleTrack(track.artist, track.title)
	' 		end if
	' 	end if
	' end if

	if NowPlayingScreen <> invalid
		timer = GetNowPlayingTimer()

		if timer <> invalid
			if timer <> invalid AND timer.totalSeconds() >= 5'GetConfig().MetadataFetchTimer + song.JSONDownloadDelay then
				if station <> invalid
					Get_Metadata(station, GetPort())
				end if

				timer.mark()
			end if
		end if
'
  	' 'Now Playing on other stations
  	' if (Session.StationDownloads <> invalid AND Session.StationDownloads.Timer <> invalid AND Session.StationDownloads.Timer.totalSeconds() > GetConfig().MetadataFetchTimer)
  	' 	CancelOtherStationsNowPlayingRequests()
  	' end if

  	' if NowPlayingScreen.NowPlayingOtherStationsTimer <> invalid AND NowPlayingScreen.NowPlayingOtherStationsTimer.totalSeconds() > 1000
	'     NowPlayingScreen.NowPlayingOtherStationsTimer.mark()
  	' 	CreateOtherStationsNowPlaying()
  	' end if

		'Image download timeouts
		if track.ArtistImageDownloadTimer <> invalid AND track.ArtistImageDownloadTimer.totalSeconds() > GetConfig().ImageDownloadTimeout
			if NowPlayingScreen.artistImage = invalid OR NowPlayingScreen.artistImage.valid <> true
				track.UseFallbackArtistImage = true
				track.ArtistImageDownloadTimer = invalid
				NowPlayingScreen.UpdateScreen()
			end if
		end if

		if track.BackgroundImageDownloadTimer <> invalid AND track.BackgroundImageDownloadTimer.totalSeconds() > GetConfig().ImageDownloadTimeout
			if NowPlayingScreen.BackgroundImage = invalid OR NowPlayingScreen.BackgroundImage.valid <> true
				track.UseFallbackBackgroundImage = true
				track.BackgroundImageDownloadTimer = invalid
				NowPlayingScreen.UpdateScreen()
			end if
		end if
	end if

End Sub


' Sub HandleAudioPlayerEvent(msg as Object)
' 	if type(msg) = "roAudioPlayerEvent"  then	' event from audio player
' 	Audio = GetGlobalAA().AudioPlayer
' 	Station = Audio.station
' 	song = GetGlobalAA().SongObject

' 	    if msg.isStatusMessage() then
' 	        'message = msg.getMessage()
' 	    else if msg.isListItemSelected() then
' 	        Station.failCounter = 0
' 	    else if msg.isRequestSucceeded() OR msg.isRequestFailed()
' 	    	if Audio.failCounter < 5 then

' 				if Audio.FailCounter > 2
' 					url = Station.url
' 					print "Attempting to sanitize url: " + url
' 					url = SanitizeStreamUrl(url)
' 					Audio.updateStreamUrl(url)
' 				end if

' 	        	print "FullResult: End of Stream. " + Station.url + "  Restarting.  Failures: " + str(Audio.failCounter)
' 	        	Audio.AudioPlayer.stop()
' 	        	Audio.AudioPlayer.play()
' 						Audio.Audioplayer.Seek(-180000)
' 	        	Audio.failCounter = Audio.failCounter + 1
' 	        else
' 	        	BatLog("Failed playing station: " + Station.url)
'             GetGlobalAA().SongObject = invalid
' 	        	Audio.AudioPlayer.stop()
' 	        	Audio.failCounter = 0
' 	        	ListStations()
' 	        end if
' 	    endif
' 	endif
' End Sub

Sub HandleDownloadEvents(msg)

	if type(msg) = "roUrlEvent" then

		Identity = ToStr(msg.GetSourceIdentity())
		Downloads = GetSession().Downloads
		NowPlayingScreen = GetGlobalAA().SavedNowPlayingScreen
		track = GetGlobalAA().track
		
		if NowPlayingScreen = invalid
			return
		end if

		if msg.GetResponseCode() = 200 OR msg.GetFailureReason() = invalid then

			IsDownloadingFile = IsDownloading(Identity)
			if IsDownloadingFile = true then
				NowPlayingScreen.UpdateScreen()
			end if

			'JSON
			if GetGlobalAA().DoesExist("jsontransfer")
				jsontransfer = GetGlobalAA().Lookup("jsontransfer")
				jsonIdentity = ToStr(jsontransfer.GetIdentity())

				if jsonIdentity = Identity then
					' Check if this is a cached version'
					headers = msg.GetResponseHeaders()
					if headers.DoesExist("etag") AND GetGlobalAA().DoesExist("jsonEtag") AND GetGlobalAA().jsonEtag = headers.etag
						GetGlobalAA().Delete("jsontransfer")
						return
					end if

					GetGlobalAA().jsonEtag = headers.etag
					HandleJSON(msg.GetString())
					GetGlobalAA().Delete("jsontransfer")
				End if
			end if

			if GetGlobalAA().DoesExist(Identity) THEN
				GetGlobalAA().Delete(Identity)
			End if

			'Downloads for what other stations are playing
			' if (IsOtherStationsValidDownload(msg))
			' 	CompletedOtherStationsMetadata(msg)
			' end if

		else
			TransferRequest = Downloads.lookup(Identity)
			if TransferRequest <> invalid
				errorUrl = TransferRequest.GetUrl()
				'BatLog("Download failed. " + errorUrl + " " + str(msg.GetResponseCode()) + " : " + msg.GetFailureReason(), "error")
			else
				'BatLog("Download failed. " + str(msg.GetResponseCode()) + " : " + msg.GetFailureReason(), "error")
			endif

			if GetGlobalAA().DoesExist("jsontransfer")
				jsontransfer = GetGlobalAA().Lookup("jsontransfer")
				jsonIdentity = ToStr(jsontransfer.GetIdentity())
				if jsonIdentity = Identity
					HandleJSON(msg)
				end if
			end if

			if IsBackgroundImageDownload(Identity)
				'Background Image download failed
				BatLog("Using background fallback image.")
				track.UseFallbackBackgroundImage = true
				GetSession().BackgroundImageDownload = invalid
				NowPlayingScreen.UpdateScreen()
				return
			end if

			if IsArtistImageDownload(Identity)
				'Artist Image download failed
				BatLog("Using artist fallback image.")
				track.UseFallbackArtistImage = true
				GetSession().ArtistImageDownload = invalid
				NowPlayingScreen.UpdateScreen()
				return
			end if

			'Handle JSON download failures
			if GetGlobalAA().DoesExist("jsontransfer")
				jsontransfer = GetGlobalAA().Lookup("jsontransfer")
				jsonIdentity = ToStr(jsontransfer.GetIdentity())
				if jsonIdentity = Identity then
					GetGlobalAA().Delete("jsontransfer")
					if track.MetadataFetchFailure = invalid then track.MetadataFetchFailure = 0
					track.MetadataFetchFailure = track.MetadataFetchFailure + 1
					timer = GetNowPlayingTimer()
					timer.mark()
				End if

			end if


		end if

	end if

End Sub

'Utilities

function StartEventLoop()
  port = GetPort()
	GetGlobalAA().AddReplace("endloop", false)

	while NOT GetGlobalAA().lookup("endloop")
		HandleTimers()

		msg = port.GetMessage() ' get a message, if available

		HandleWebEvent(msg)

		if msg <> invalid then
			HandleDownloadEvents(msg)

		    msgType = type(msg)

			HandleNowPlayingScreenEvent(msg)

			if msgType = "roSGNodeEvent"
				' Display Now Playing screen
				if msg.getField() = "station"
					node = msg.getData()
					stationAA = createObject("roAssociativeArray")
					stationAA.name = node.name
					stationAA.image = node.image
					stationAA.url = node.url
					GetGlobalAA().station = stationAA
					stationChanged(stationAA)					
				end if

				if msg.getField() = "track"
					track = msg.getData()
					trackChanged(track)
				end if

			end if
		end if

		' If there is a station determine if we need to be drawing the
		' now playing screen.
		if GetGlobalAA().station <> invalid'' AND GetGlobalAA().DoesExist("track")
			NowPlayingScreen = GetGlobalAA().SavedNowPlayingScreen

			if NowPlayingScreen <> invalid AND NowPlayingScreen.screen <> invalid 
				NowPlayingScreen.DrawScreen()
			end if
		end if

    'Analytics
    ' BatAnalytics_Handle(msg)

	end while

end function


function StopEventLoop()
	GetGlobalAA().AddReplace("endloop", true)
end function


Sub GetPort() as Object
	port = GetGlobalAA().lookup("port")

	if port = invalid then
		port = CreateObject("roMessagePort")
		GetGlobalAA().AddReplace("port", port)
		return port
	end if

	return port
End Sub
