Function GetJSONAtUrl(url as String)
  NowPlayingScreen = GetNowPlayingScreen()

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
    'print "Checking for JSON at " metadataUrl
    Request.SetUrl(metadataUrl)
    GetGlobalAA().AddReplace("jsontransfer", Request)

    Request.AsyncGetToString()
  end if
End Function


Function HandleJSON(jsonString as String)

  'Reset audio player counter on success
  Audio = GetGlobalAA().AudioPlayer
  Audio.failCounter = 0

  jsonObject = ParseJSON(jsonString)
  song = GetGlobalAA().Lookup("SongObject")
  NowPlayingScreen = GetNowPlayingScreen()

  song.backgroundimage = song.hdposterurl
  song.artistimage = song.stationimage
  song.UsedFallbackImage = true

  if song.MetadataFetchFailure = invalid
    song.MetadataFetchFailure = 0
    song.metadataFault = true
  end if

  shouldRefresh = false
  song.UseFallbackArtistImage = false
  song.UseFallbackBackgroundImage = false

  if jsonObject <> invalid AND jsonObject.song <> invalid

    song.JSONDownloadDelay = 0

    'Station details if available
    if jsonObject.station <> invalid
      if NOT song.DoesExist("StationDetails") OR song.StationDetails.listeners <> jsonObject.station.listeners
        song.StationDetails = jsonObject.station
        song.StationDetails.updated = true
      end if
    end if

    song.Title = jsonObject.song
    song.Artist = jsonObject.artist
    'song.Description = jsonObject.bio
    song.bio = jsonObject.bio
    song.Genres = jsonObject.tags
    song.isOnTour = jsonObject.isOnTour
    song.album = jsonObject.album
    song.metadataFault = false
    song.brightness = 0
    song.metadataFetched = jsonObject.metaDataFetched
    song.PopularityFetchCounter = 0
    song.MetadataFetchFailure = 0

    if jsonObject.image <> invalid AND jsonObject.image.url <> "" AND jsonObject.image.url <> invalid
      song.image = jsonObject.image 'Used for colors
      song.artistimage = jsonObject.image.url
      song.UsedFallbackImage = false

      if jsonObject.image.backgroundurl <> invalid AND isnonemptystr(jsonObject.image.backgroundurl)
        song.backgroundimage = jsonObject.image.backgroundurl
      end if

    else
      'Set a default color
      song.image = CreateObject("roAssociativeArray")
      song.image.color = CreateObject("roAssociativeArray")
      song.image.color.hex = "#ffffffff"
    end if

  else
    BatLog("There was an error processing or downloading metadata: " + song.feedurl, "error")
    song.JSONDownloadDelay = song.JSONDownloadDelay + 1
    song.Artist = song.stationName
    song.Title = song.feedurl
    song.bio = CreateObject("roAssociativeArray")
    song.bio.text = "The Bat Player displays additional information about the station and its songs when available.  " + song.stationName + " does not seem to have any data for The Bat to show you either due the Station not providing it or our services are experiencing difficulties.  Visit http://status.thebatplayer.fm for service updates."
    song.metadataFault = true
    song.metadataFetched = false
    song.album = invalid
    song.brightness = 0
    song.MetadataFetchFailure = song.MetadataFetchFailure + 1
    song.backgroundImage = song.hdposterurl
    song.artistImage = song.hdposterurl
    song.UsedFallbackImage = true
  end if

  if isnullorempty(song.artist) then
    song.artist = song.stationName
    shouldRefresh = true
  endif

  if isnullorempty(song.Title) then
    song.Title = song.stationName
    shouldRefresh = true
  endif

  if isnullorempty(song.artistImage) then
    song.artistImage = song.hdposterurl
    shouldRefresh = true
  endif

  if isnullorempty(song.backgroundImage) then
    song.backgroundImage = song.hdposterurl
    shouldRefresh = true
  endif

  NowPlayingScreen.song = song

  ' Refresh because of a successful update
  if GetGlobalAA().lastSongTitle <> song.Title AND song.metadataFault = false
    shouldRefresh = true
  endif

  ' Refresh because we've failed getting any metadata a number of times
  if song.metadataFault = true AND song.MetadataFetchFailure = 3
    shouldRefresh = true
  endif


 if shouldRefresh = true then

      RefreshNowPlayingScreen()
      GetGlobalAA().lastSongTitle = song.Title

      'Download artist image if needed
      if song.DoesExist("image")
        song.OverlayColor = CreateOverlayColor(song)

        if song.DoesExist("artistimage") AND NOT FileExists(makemdfive(song.Artist))
            song.ArtistImageDownloadTimer = CreateObject("roTimespan")
            DownloadArtistImageForSong(song)
        end if

        if song.DoesExist("backgroundimage") AND NOT FileExists("colored-" + makemdfive(song.Artist))
          song.BackgroundImageDownloadTimer = CreateObject("roTimespan")
          DownloadBackgroundImageForSong(song)
        endif
      end if

      DownloadAlbumImageForSong(song)

      if NowPlayingScreen.scrobbleTimer = invalid then
        NowPlayingScreen.scrobbleTimer = CreateObject("roTimespan")
      end if
      NowPlayingScreen.scrobbleTimer.mark()

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
