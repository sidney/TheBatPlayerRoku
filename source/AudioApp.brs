

Sub Get_Metadata(song as Object, port as Object)
        GetJSONAtUrl(song.stream)
End Sub

REM ******************************************************
REM
REM Show audio screen
REM
REM Upon entering screen, should start playing first audio stream
REM
REM ******************************************************
Sub Show_Audio_Screen(station as Object)
  GetGlobalAA().AddReplace("NowPlaying", true)

    'If we're already playing this station then don't make any changes
    ' if GetGlobalAA().DoesExist("SongObject")
    '   CurrentStation = GetGlobalAA().SongObject
    '   if CurrentStation <> invalid
    '     if CurrentStation.stream = Station.stream
    '       RefreshNowPlayingScreen()
    '       return
    '     end if
    '   end if
    ' end if

    ' ResetNowPlayingScreen()

    if GetGlobalAA().DoesExist("AudioPlayer") then
      Audio = GetGlobalAA().AudioPlayer
      Audio.reset()
      GetGlobalAA().song = ""
    else
      Audio = AudioInit()
      GetGlobalAA().AudioPlayer = Audio
    end if

    GetGlobalAA().AddReplace("SongObject", Station)

    Audio.setPlayState(0)
    Audio.setupSong(station.stream.trim(), "mp3")
    Audio.audioplayer.setNext(0)
    Audio.setPlayState(2)		' start playing
    Audio.audioplayer.Seek(-180000)
End Sub

Function PlayStation(station)
  if station.DoesExist("stream") AND station.stream <> ""
    'Analytics_StationSelected(Station.stationName, Station.stream)

    ' metadataUrl = GetConfig().Batserver + "metadata/" + UrlEncode(Station.stream.trim())
    ' print "JSON for selected station: " + metadataUrl
    '
    'DisplayStationLoading(Station)
    Show_Audio_Screen(Station)
  end if
End Function


Function CreateSong(title as string, description as string, artist as string, streamformat as dynamic, stream as string, imagelocation as string) as Object
    item = CreatePosterItem("", title, description)
    
    url = imageLocation

    if streamformat = invalid
      streamformat = "mp3"
    end if

    item.Artist = artist
    item.Title = title    ' Song name
    item.name = title
    item.stream = stream
    item.streamformat = streamformat
    item.picture = url      ' default audioscreen picture to PosterScreen Image
    item.stationProvider = description
    item.stationName = title
    item.StationImage = imagelocation
    item.Description = "Select Station to find what is currently playing."
    item.JSONDownloadDelay = 0
    item.dataExpires = 0
    item.HDPosterUrl = url
    item.SDPosterUrl = item.HDPosterUrl
    return item
End Function
