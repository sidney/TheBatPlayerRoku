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
      GetGlobalAA().NowPlayingScreen = invalid

      StationSelectionScreen = GetGlobalAA().StationSelectionScreen
      StationSelectionScreen.RefreshNowPlayingData()

      GetGlobalAA().lastSongTitle = invalid
			GetGlobalAA().IsStationSelectorDisplayed = true

	  else if key = 106
			' Display help message
			DisplayHelpPopup()
	  end if

  end if

End Sub

Sub HandleTimers()
	song = GetGlobalAA().SongObject
	NowPlayingScreen = GetNowPlayingScreen()
	Session = GetSession()

	if GetGlobalAA().IsStationSelectorDisplayed <> true then
		timer = GetNowPlayingTimer()
		if timer <> invalid

			if timer <> invalid and timer.totalSeconds() >= GetConfig().MetadataFetchTimer + song.JSONDownloadDelay then
				Get_Metadata(song, GetPort())
				timer.mark()
			end if
		end if


		'LastFM Scrobbles
		if NowPlayingScreen.scrobbleTimer <> invalid THEN
			if NowPlayingScreen.scrobbleTimer.totalSeconds() >= 15 then
				if song.Artist <> invalid and song.Title <> invalid and song.metadatafault <> true and song.metadataFetched = true
					NowPlayingScreen.scrobbleTimer = invalid
      				ScrobbleTrack(song.Artist, song.Title)
      	end if
      end if
    end if

  	'Now Playing on other stations
  	if (Session.StationDownloads <> invalid AND Session.StationDownloads.Timer <> invalid AND Session.StationDownloads.Timer.totalSeconds() > GetConfig().MetadataFetchTimer)
  		CancelOtherStationsNowPlayingRequests()
  	end if

  	if NowPlayingScreen.NowPlayingOtherStationsTimer <> invalid AND NowPlayingScreen.NowPlayingOtherStationsTimer.totalSeconds() > 1000
	    NowPlayingScreen.NowPlayingOtherStationsTimer.mark()
  		CreateOtherStationsNowPlaying()
  	end if

		'Image download timeouts
		if song.ArtistImageDownloadTimer <> invalid AND song.ArtistImageDownloadTimer.totalSeconds() > GetConfig().ImageDownloadTimeout
			if NowPlayingScreen.artistImage = invalid OR NowPlayingScreen.artistImage.valid <> true
				song.UseFallbackArtistImage = true
				song.ArtistImageDownloadTimer = invalid
				UpdateScreen()
			end if
		end if

		if song.BackgroundImageDownloadTimer <> invalid AND song.BackgroundImageDownloadTimer.totalSeconds() > GetConfig().ImageDownloadTimeout
			if NowPlayingScreen.BackgroundImage = invalid OR NowPlayingScreen.BackgroundImage.valid <> true
				song.UseFallbackBackgroundImage = true
				song.BackgroundImageDownloadTimer = invalid
				UpdateScreen()
			end if
		end if

	end if

End Sub


Sub HandleAudioPlayerEvent(msg as Object)
	if type(msg) = "roAudioPlayerEvent"  then	' event from audio player
	Audio = GetGlobalAA().AudioPlayer
	Station = Audio.station
	song = GetGlobalAA().SongObject

	    if msg.isStatusMessage() then
	        'message = msg.getMessage()
	    else if msg.isListItemSelected() then
	        Station.failCounter = 0
	    else if msg.isRequestSucceeded() OR msg.isRequestFailed()
	    	if Audio.failCounter < 5 then

						if Audio.FailCounter > 2 AND (Station.url.Right(1) <> "/" OR Station.url.Right(2) <> "/;")
							url = Station.url
							print "Attempting to sanitize url: " + url
							url = SanitizeStreamUrl(url)
							Audio.updateStreamUrl(url)
						end if

	        	print "FullResult: End of Stream. " + Station.url + "  Restarting.  Failures: " + str(Audio.failCounter)
	        	Audio.AudioPlayer.stop()
	        	Audio.AudioPlayer.play()
						Audio.Audioplayer.Seek(-180000)
	        	Audio.failCounter = Audio.failCounter + 1
	        else
	        	BatLog("Failed playing station: " + Station.url)
            GetGlobalAA().SongObject = invalid
	        	Audio.AudioPlayer.stop()
	        	Audio.failCounter = 0
	        	ListStations()
	        end if
	    endif
	endif
End Sub

Sub HandleDownloadEvents(msg)
	if type(msg) = "roUrlEvent" then
		Identity = ToStr(msg.GetSourceIdentity())
		Downloads = GetSession().Downloads
		TransferRequest = Downloads.lookup(Identity)

		if msg.GetResponseCode() = 200 OR msg.GetFailureReason() = invalid then

			IsDownloadingFile = IsDownloading(Identity)
			if IsDownloadingFile = true then
				song = GetGlobalAA().SongObject
				if GetGlobalAA().IsStationSelectorDisplayed <> true
					UpdateScreen()
				end if
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
			if (IsOtherStationsValidDownload(msg))
				CompletedOtherStationsMetadata(msg)
			end if

		else
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

			song = GetGlobalAA().SongObject

			if IsBackgroundImageDownload(Identity)
				'Background Image download failed
				BatLog("Using background fallback image.")
				song.UseFallbackBackgroundImage = true
				GetSession().BackgroundImageDownload = invalid
				UpdateScreen()
				return
			end if

			if IsArtistImageDownload(Identity)
				'Artist Image download failed
				BatLog("Using artist fallback image.")
				song.UseFallbackArtistImage = true
				GetSession().ArtistImageDownload = invalid
				UpdateScreen()
				return
			end if

			'Handle JSON download failures
			if GetGlobalAA().DoesExist("jsontransfer")
				jsontransfer = GetGlobalAA().Lookup("jsontransfer")
				jsonIdentity = ToStr(jsontransfer.GetIdentity())
				if jsonIdentity = Identity then
					GetGlobalAA().Delete("jsontransfer")
					if song.MetadataFetchFailure = invalid then song.MetadataFetchFailure = 0
					song.MetadataFetchFailure = song.MetadataFetchFailure + 1
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

			if GetGlobalAA().IsStationLoadingDisplayed = true AND type(msg) = "roImageCanvasEvent"
				HandleStationLoadingScreenEvent(msg)
			end if

			if GetGlobalAA().IsStationSelectorDisplayed = true AND type(msg) = "roGridScreenEvent"
        StationSelectionScreen = GetGlobalAA().StationSelectionScreen
				StationSelectionScreen.Handle(msg)
			end if

			HandleDownloadEvents(msg)
			HandleNowPlayingScreenEvent(msg)
			HandleAudioPlayerEvent(msg)
		end if

		song = GetGlobalAA().SongObject
		if GetGlobalAA().IsStationSelectorDisplayed <> true
			NowPlayingScreen = GetNowPlayingScreen()

			if NowPlayingScreen <> invalid AND NowPlayingScreen.screen <> invalid AND NowPlayingScreen.DoesExist("song")
				DrawScreen()
			end if
		end if

    'Analytics
    BatAnalytics_Handle(msg)

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
