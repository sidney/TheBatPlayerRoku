Sub Get_Metadata(station as Object, port as Object)
	screen = GetGlobalAA().SavedNowPlayingScreen

	if screen = invalid
		return
	end if

  GetJSONAtUrl(station.url)
End Sub

Function GetJSONAtUrl(url as String)
  'NowPlayingScreen = GetNowPlayingScreen()

  if NOT GetGlobalAA().DoesExist("jsontransfer") then
    Request = GetRequest()

    'Sanitize the stream url to get the correct metadata
    if right(url,1) = "/" then
      url = left(url, len(url)-1)
    else if right(url,2) = "/;" then
      url = left(url, len(url)-2)
    end if

    url = UrlEncode(url)
    metadataUrl = GetConfig().Batserver + "metadata/" + url
    print "Checking for JSON at " metadataUrl
    Request.SetUrl(metadataUrl)
    GetGlobalAA().jsontransfer = Request
    response = Request.GetToString()
    'Request.AsyncGetToString()
	GetGlobalAA().Delete("jsontransfer")

	HandleJSON(response)
  end if
End Function


Function HandleJSON(jsonString as String)

  'Reset audio player counter on success
'   Audio = GetGlobalAA().AudioPlayer
'   Audio.failCounter = 0

  jsonObject = ParseJSON(jsonString)
  station = GetGlobalAA().Lookup("station")
  'NowPlayingScreen = GetNowPlayingScreen()


  if station = invalid
    return false
  end if
  
  track = createObject("roAssociativeArray")

  track.backgroundimage = station.image
  track.artistimage = station.image
  track.UsedFallbackImage = true

'   if song.MetadataFetchFailure = invalid
'     song.MetadataFetchFailure = 0
'     song.metadataFault = true
'   end if

  shouldRefresh = false
  track.UseFallbackArtistImage = false
  track.UseFallbackBackgroundImage = false

  if jsonObject <> invalid AND jsonObject.song <> invalid

    'song.JSONDownloadDelay = 0

    'Station details if available
    ' if jsonObject.station <> invalid
    '   if NOT song.DoesExist("StationDetails") OR song.StationDetails.listeners <> jsonObject.station.listeners
    '     song.StationDetails = jsonObject.station
    '     song.StationDetails.updated = true
    '   end if
    ' end if

    track.Title = jsonObject.song
    track.Artist = jsonObject.artist
    'song.Description = jsonObject.bio
    track.bio = jsonObject.bio
    track.Genres = jsonObject.tags
    track.isOnTour = jsonObject.isOnTour
    track.album = jsonObject.album
    track.metadataFault = false
    track.brightness = 0
    track.metadataFetched = jsonObject.metaDataFetched
    track.PopularityFetchCounter = 0
    track.MetadataFetchFailure = 0

    if jsonObject.image <> invalid AND jsonObject.image.url <> "" AND jsonObject.image.url <> invalid
      track.image = jsonObject.image 'Used for colors
      track.artistimage = jsonObject.image.url
      track.UsedFallbackImage = false

      if jsonObject.image.backgroundurl <> invalid AND isnonemptystr(jsonObject.image.backgroundurl)
        track.backgroundimage = jsonObject.image.backgroundurl
      end if

    else
      'Set a default color
      track.image = CreateObject("roAssociativeArray")
      track.image.color = CreateObject("roAssociativeArray")
      track.image.color.hex = "#ffffffff"
    end if

  else
    BatLog("There was an error processing or downloading metadata: " + station.url, "error")
   '' track.JSONDownloadDelay = song.JSONDownloadDelay + 1
    track.Artist = station.name
    track.Title = station.url
    track.bio = CreateObject("roAssociativeArray")
    track.bio.text = "The Bat Player displays additional information about the station and its songs when available.  " + station.name + " does not seem to have any data for The Bat to show you either due the Station not providing it or our services are experiencing difficulties."
    track.metadataFault = true
    track.metadataFetched = false
    track.album = invalid
    track.brightness = 0
    'track.MetadataFetchFailure = station.MetadataFetchFailure + 1
    track.backgroundImage = station.image
    track.artistImage = station.image
    track.UsedFallbackImage = true
  end if

  if isnullorempty(track.artist) then
    track.artist = station.name
    shouldRefresh = true
  endif

  if isnullorempty(track.Title) then
    track.Title = station.name
    shouldRefresh = true
  endif

  if isnullorempty(track.artistImage) then
    track.artistImage = station.image
    shouldRefresh = true
  endif

  if isnullorempty(track.backgroundImage) then
    track.backgroundImage = station.image
    shouldRefresh = true
  endif

  'NowPlayingScreen.song = song

  ' Refresh because of a successful update
  if GetGlobalAA().lastTrackTitle = invalid
  	shouldRefresh = true
  else if track <> invalid AND GetGlobalAA().lastTrackTitle <> track.title'' AND station.metadataFault = false
    shouldRefresh = true
  endif

  ' Refresh because we've failed getting any metadata a number of times
'   if song.metadataFault = true AND song.MetadataFetchFailure = 3
'     shouldRefresh = true
'   endif

 if shouldRefresh = true then

      'RefreshNowPlayingScreen()
      GetGlobalAA().lastTrackTitle = track.Title

      'Download artist image if needed
      if track.DoesExist("image")
        track.OverlayColor = CreateOverlayColor(track)

        if track.DoesExist("artistimage") AND NOT FileExists(makemdfive(track.Artist))
            track.ArtistImageDownloadTimer = CreateObject("roTimespan")
            DownloadArtistImageForSong(track)
        end if

        if track.DoesExist("backgroundimage") AND NOT FileExists("colored-" + makemdfive(track.Artist))
          track.BackgroundImageDownloadTimer = CreateObject("roTimespan")
          DownloadBackgroundImageForSong(track)
        endif
      end if

      DownloadAlbumImageForSong(track)

	  TrackChanged(track)

      ' if NowPlayingScreen.scrobbleTimer = invalid then
      '   NowPlayingScreen.scrobbleTimer = CreateObject("roTimespan")
      ' end if
      ' NowPlayingScreen.scrobbleTimer.mark()

  end if

End Function

Function FetchMetadataForStreamUrlAndName(url as string, name as string, usedForStationSelector = false as Boolean, stationSelectorIndex = invalid as dynamic)
	Session = GetSession()

	if url <> invalid
		url = GetConfig().Batserver + "nowplaying/" + UrlEncode(url)

		Request = GetRequest()
		Request.SetUrl(url)
		Request.SetPort(GetPort())
		if Request.AsyncGetToString() then

			stationRequestObject = CreateObject("roAssociativeArray")
			stationRequestObject.name = name
			stationRequestObject.request = Request
      stationRequestObject.usedForStationSelector = usedForStationSelector
      stationRequestObject.stationSelectorIndex = stationSelectorIndex

			key = "OtherStationsRequest-" + ToStr(Request.GetIdentity())
			Session.StationDownloads.Downloads.AddReplace(key, stationRequestObject)

      if usedForStationSelector = false
        Session.StationDownloads.Count = Session.StationDownloads.Count + 1
      end if
		else
			BatLog("Failed downloading accessing " + url)
		end if

	end if
End Function

Function CompletedOtherStationsMetadata(msg as Object)
  Session = GetSession()
  Completed = Session.StationDownloads.Completed

  if msg <> invalid
  	Identity = ToStr(msg.GetSourceIdentity())
  	key = "OtherStationsRequest-" + Identity
    jsonObject = ParseJSON(msg.GetString())
    track = jsonObject.title

    'If there's no data then don't deal with it
    if track = invalid
      return false
    end if

  	stationRequestObject = Session.StationDownloads.Downloads.Lookup(key)
  	Session.StationDownloads.Downloads.Delete(key)

    if stationRequestObject.usedForStationSelector = true
      StationSelectorNowPlayingTrackReceived(track, stationRequestObject.stationSelectorIndex)
      return false
    end if

  	CompletedObject = CreateObject("roAssociativeArray")
  	CompletedObject.name = stationRequestObject.name
  	CompletedObject.playing = track

  	Completed.push(CompletedObject)
  end if

	if AssocArrayCount(Session.StationDownloads.Downloads) = 0

		'Cleanup
		Session.StationDownloads.Downloads.Clear()
		Session.StationDownloads.Delete("Completed")
		Session.StationDownloads.Count = 0
    Session.StationDownloads.Timer = invalid

		'All the downloads are complete let's display them
		DisplayOtherStationsNowPlaying(Completed)
	end if

End Function

Function IsOtherStationsValidDownload(msg as Object) as Boolean
	Session = GetSession()

	if type(msg) = "roUrlEvent" AND Session.DoesExist("StationDownloads") AND Session.StationDownloads.DoesExist("Downloads")
		Identity = ToStr(msg.GetSourceIdentity())
		key = "OtherStationsRequest-" + Identity

		if Session.StationDownloads.Downloads.DoesExist(key)
			return true
		end if
	end if

	return false

End Function
