'Called only once when the Now Playing screen is displayed
Function CreateNowPlayingScreen() as Object

  Analytics = GetSession().Analytics
  Analytics.ViewScreen("Now Playing")

	NowPlayingScreen = CreateObject("roAssociativeArray")

	this = {
    Width: GetSession().deviceInfo.GetDisplaySize().w
    Height: GetSession().deviceInfo.GetDisplaySize().h

    headerFont: GetHeaderFont()
    boldFont: GetLargeFont()
    defaultFont: GetMediumFont()
    smallFont: GetSmallFont()
    songNameFont: GetSongNameFont()

    HeaderLogo: CreateObject("roBitmap", "pkg:/images/bat.png")
    HeaderHeight: ResolutionY(90)
    StationDetailsLabel: invalid
    StationTitleLabel: invalid

    BackgroundImage: invalid
    PreviousBackgroundImage: invalid


    albumImage: invalid
    previousAlbumImage: invalid

    ArtistImage: invalid
    previousArtistImage: invalid

    artistNameLabel: invalid
    PreviousArtistNameLabel: invalid

    songNameLabel: invalid
    PreviousSongNameLabel: invalid

    bioLabel: invalid
    PreviousBioLabel: invalid

    albumNameLabel: invalid
    PreviousAlbumNameLabel: invalid

    lastfmlogo: CreateObject("roBitmap", "pkg:/images/audioscrobbler_black.png")
    albumPlaceholder: invalid
    AlbumShadow: RlGetScaledImage(CreateObject("roBitmap", "pkg:/images/album-shadow.png"), ResolutionX(200), ResolutionY(200), 1)

    UpdateBackgroundImage: true
    UpdateArtistImage: true
    UpdateAlbumImage: true

    YOffset: 0

    ScrobbleTimer: invalid
    NowPlayingOtherStationsTimer: invalid

    popup: invalid
    loadingScreen: invalid

    screen: invalid
    NowPlayingOtherStationsTimer: CreateObject("roTimespan")

    HelpLabel: invalid

    ResetNowPlayingScreen: nowplaying_ResetNowPlayingScreen
    RefreshNowPlayingScreen: nowplaying_RefreshNowPlayingScreen
    UpdateScreen: nowplaying_UpdateScreen
    DrawScreen: nowplaying_DrawScreen
  }

  this.helplabel = RlText("Press OK for help", GetExtraSmallFont(), &hFFFFFF77,  this.Width - 140, ResolutionY(70))

	return this
End Function

Function nowplaying_ResetNowPlayingScreen()
	GetGlobalAA().Delete("NowPlayingScreen")
	GetGlobalAA().Delete("Song")
  NowPlayingScreen = GetNowPlayingScreen()
  NowPlayingScreen.NowPlayingOtherStationsTimer.mark()
End Function

Function nowplaying_RefreshNowPlayingScreen()
  print "RefreshNowPlayingScreen()"

  ' NowPlayingScreen = GetNowPlayingScreen()

  song = GetGlobalAA().track

  ' if song = invalid
  '   if NowPlayingScreen <> invalid AND NowPlayingScreen.DoesExist("screen")
  '     NowPlayingScreen.screen = invalid
  '     return false
  '   end if
  ' end if

  ' GetGlobalAA().lastSongTitle = invalid

  m.YOffset = 0
  bioText = GetBioTextForSong(song)
  if bioText = invalid OR bioText = ""
    m.YOffset = 60
  end if

  if m.artistImage <> invalid
    if SupportsAdvancedFeatures()
      m.previousArtistImage = m.artistImage
      m.previousArtistImage.FadeIn()
    end if
    m.artistImage.FadeOut()
  end if

  ' if m.albumImage <> invalid
  '   if SupportsAdvancedFeatures()
  '     m.previousAlbumImage = m.albumImage
  '     m.previousAlbumImage.FadeIn()
  '   end if
  '   m.albumImage.FadeOut()
  ' end if

  ' if m.BackgroundImage <> invalid
  '   if SupportsAdvancedFeatures()
  '     m.PreviousBackgroundImage = m.BackgroundImage
  '     m.PreviousBackgroundImage.FadeOut()
  '   end if
  ' end if

  ' Album placeholder.  Only recreate it if we have to move it.
  ' albumPlaceholderY = 240 + m.YOffset
  ' if m.albumPlaceholder = invalid OR m.albumPlaceholder.y <> albumPlaceholderY
  '   m.albumPlaceholder = AlbumImage("pkg:/images/album-placeholder.png", 830, albumPlaceholderY, true, 255, 0)
  ' end if

  m.UpdateBackgroundImage = true
  m.UpdateArtistImage = true
  m.UpdateAlbumImage = true

  m.stationTitle = GetGlobalAA().station.name

  RunGarbageCollector()
  m.UpdateScreen()

  ' if song.metadataFault <> true AND song.artist <> invalid AND song.title <> invalid
  '   Analytics_TrackChanged(song.artist, song.title, song.stationName)
  ' end if
End Function

'Called whenever the data for the screen changes (song)
Function nowplaying_UpdateScreen()
  print "UpdateScreen()"
	
  ' NowPlayingScreen = GetNowPlayingScreen()
  song = GetGlobalAA().track
  station = GetGlobalAA().station

  m.song = song
  ' if song = invalid
  '   return false
  ' end if

  albumTitle = ""
  songTitle = ""
  bioText = GetBioTextForSong(song)

  if m.screen = invalid
    print "Creating roScreen"
    screen = CreateObject("roScreen", true, m.Width, m.Height)
    m.screen = screen

    screen.setalphaenable(true)
    screen.SetMessagePort(GetPort())
    'print "Clearing screen..."
    'screen.Clear(&h000000FF)
    'print "Cleared screen."

    GetGlobalAA().IsStationSelectorDisplayed = false
    GetGlobalAA().IsStationLoadingDisplayed = false

    ' StationLoadingScreen = GetGlobalAA().StationLoadingScreen
    ' if StationLoadingScreen <> invalid
    '   StationLoadingScreen.close()
    ' end if
  end if

  	'Station Name
    ' if song.stationProvider <> song.stationName then
    '   NowPlayingScreen.stationTitle = song.stationName + " - " + song.stationProvider
    ' else if song.stationTitle <> invalid
    '   NowPlayingScreen.stationTitle = song.stationName
    ' end if

    if station <> invalid AND station.name <> invalid
      stationName = station.name
      headerTitleY = 28
       m.StationTitleLabel = RlTextArea(stationName, m.headerFont, &hDDDDDD00 + 200, 180, headerTitleY, m.screen.GetWidth() - 200, 90, 1, 1.0, "left", true, false)
    end if

  'Lighting
  if GetGlobalAA().lookup("song") <> song.Title AND song.DoesExist("image") AND song.image.DoesExist("color") AND song.image.color <> invalid AND song.image.color.DoesExist("rgb") then
    SetLightsToColor(song.image.color.rgb)
  end if

	GetGlobalAA().AddReplace("song", song.title)

  if m.song.DoesExist("image") AND m.song.image.DoesExist("color") AND m.song.image.color.DoesExist("rgb") AND m.song.image.color.rgb <> invalid
    colorOffset = GetGrungeColorOffsetForColor(m.song.image.color.rgb.red, m.song.image.color.rgb.green, m.song.image.color.rgb.blue)
    m.backgroundGrungeColor = MakeARGB(m.song.image.color.rgb.red + colorOffset, m.song.image.color.rgb.green + colorOffset, m.song.image.color.rgb.blue + colorOffset, 200)
  else
    m.backgroundGrungeColor = &hFFFFFF00 + 255
  end if

  'No image?
  if NOT song.DoesExist("image") then
    song.image = CreateObject("roAssociativeArray")
  end if

  if NOT song.image.DoesExist("color") OR song.image.color.rgb = invalid OR song.image.color.hex = invalid
    song.image.color = CreateObject("roAssociativeArray")
    song.image.color.hex = "#ffffffff"
  end if

  m.song.OverlayColor = CreateOverlayColor(song)

  'Artist Image
  ' if song.UseFallbackArtistImage = true
  '   NowPlayingScreen.artistImage = ArtistImage("tmp:/" + makemdfive(station.image), NowPlayingScreen.yOffset)
  ' else if isstr(song.artistimage) AND FileExists(makemdfive(song.artistimage)) then
  '   artistImageFilePath = "tmp:/" + makemdfive(song.artistimage)

  '   if artistImageFilePath <> invalid AND NowPlayingScreen.UpdateArtistImage = true then
  '     NowPlayingScreen.artistImage = ArtistImage(artistImageFilePath, NowPlayingScreen.YOffset)

  '     if NowPlayingScreen.artistImage = invalid
  '       song.UseFallbackArtistImage = true
  '       NowPlayingScreen.UpdateArtistImage = true
  '     else
  '       NowPlayingScreen.UpdateArtistImage = false
  '     end if

  '   end if
  ' end if


  'Song Name
  if song.Title <> invalid then
 		songTitle = song.Title
  end if

  'Album Image
  if type(song.album) = "roAssociativeArray" AND song.album.DoesExist("name") AND song.album.name <> invalid AND FileExists("album-" + makemdfive(song.album.name + song.artist)) AND m.UpdateAlbumImage = true then
    albumImageFilePath = "tmp:/album-" + makemdfive(song.album.name + song.artist)
    m.albumImage = AlbumImage(albumImageFilePath, 830, 240 + m.YOffset, true, 255, CreateAlbumOverlayColor(song))
    m.UpdateAlbumImage = false
  endif

  if type(song.album) = "roAssociativeArray" AND song.album.DoesExist("name") AND song.album.name <> invalid
    'Album Name
    if (song.album.DoesExist("released") AND song.album.released <> invalid) then
      albumTitle = song.album.name + " (" + ToStr(song.album.released) + ")"
    else
      albumTitle = song.album.name
    endif
  endif


  'Background Image
 	if song.backgroundimage <> invalid AND FileExists(makemdfive(song.backgroundimage)) AND m.UpdateBackgroundImage <> false
    m.BackgroundImage = BackgroundImage("tmp:/" + makemdfive(song.backgroundimage), &hFFFFFF00 + m.song.OverlayColor, m.backgroundGrungeColor)

    if m.BackgroundImage <> invalid
      m.BackgroundImage.FadeIn()
    end if

    m.UpdateBackgroundImage = false
  else if song.UseFallbackBackgroundImage = true
    m.BackgroundImage = BackgroundImage("tmp:/" + makemdfive(song.hdposterurl))
  end if

  'Change bio label if text is different
  if m.bioLabel = invalid OR (m.bioLabel <> invalid AND m.bioLabel.text <> bioText)
    if m.bioLabel <> invalid
      m.PreviousBioLabel = m.bioLabel
      m.PreviousBioLabel.FadeOut()
    end if
    m.bioLabel = BatBioLabel(bioText, song)
    m.bioLabel.FadeIn()
  end if

  songNameHeight = GetTextHeight(songTitle, 600, m.songNameFont)
  artistNameLocation = 160 - songNameHeight + m.YOffset
  songNameLocation = artistNameLocation + 45

  'Song Name Label
  if m.songNameLabel = invalid OR (m.SongNameLabel <> invalid AND m.SongNameLabel.text <> songTitle)
    if m.SongNameLabel <> invalid
      m.PreviousSongNameLabel = m.SongNameLabel
      m.PreviousSongNameLabel.labelObject.FadeOut()
    end if
    m.songNameLabel = SongNameLabel(songTitle, song, songNameLocation, m.songNameFont, GetRegularColorForSong(song))
    m.SongNameLabel.labelObject.FadeIn()
  end if

  'Album name label
  if m.albumNameLabel = invalid OR (m.albumNameLabel <> invalid AND m.albumNameLabel.text <> albumTitle)
    if m.albumNameLabel <> invalid
      m.PreviousAlbumNameLabel = m.albumNameLabel
      m.PreviousAlbumNameLabel.FadeOut()
    end if
    m.albumNameLabel = DropShadowLabel(albumTitle, ResolutionX(740), ResolutionY(450 + m.YOffset), ResolutionX(400), ResolutionY(200), m.smallFont, GetBoldColorForSong(song), "center", 2, 2, 2)
    m.albumNameLabel.FadeIn()
  end if

  'Artist label
  if m.artistNameLabel = invalid OR (m.artistNameLabel <> invalid AND m.artistNameLabel.text <> song.artist)
    if m.artistNameLabel <> invalid
      m.PreviousArtistNameLabel = m.artistNameLabel
      m.PreviousArtistNameLabel.labelObject.FadeOut()
    end if
    m.artistNameLabel = ArtistNameLabel(song.artist, artistNameLocation, m.boldFont, GetRegularColorForSong(song))
    m.artistNameLabel.labelObject.Fadein()
  end if

  if m.artistImage <> invalid then verticalOffset = m.artistImage.verticalOffset else verticalOffset = 0

  if m.artistImage <> invalid then horizontalOffset = m.artistImage.horizontalOffset else horizontalOffset = 0

  if m.loadingScreen <> invalid then
    m.loadingScreen.close()
    m.loadingScreen = invalid
  end if

End Function

Function GetNowPlayingScreen() as Object
	NowPlayingScreen = GetGlobalAA().Lookup("NowPlayingScreen")

	if NowPlayingScreen = invalid then
		NowPlayingScreen = CreateNowPlayingScreen()
		GetGlobalAA().AddReplace("NowPlayingScreen", NowPlayingScreen)
	end if

	return NowPlayingScreen
End Function

Function nowplaying_DrawScreen()

  ' if GetGlobalAA().IsStationSelectorDisplayed = true
  '   return false
  ' end if

	' NowPlayingScreen = GetNowPlayingScreen()
  if m.screen = invalid
    return false
  end if

	if m.screen <> invalid then
		'm.screen.Clear(&h000000FF)
		'm.screen.setalphaenable(true)

		' 'Background Image
    ' if NowPlayingScreen.BackgroundImage <> invalid then
    '   NowPlayingScreen.BackgroundImage.Draw(NowPlayingScreen.screen)
    ' end if
    ' if NowPlayingScreen.PreviousBackgroundImage <> invalid
    '   NowPlayingScreen.PreviousBackgroundImage.Draw(NowPlayingScreen.screen)
    ' end if

    ' 'Overlays
    ' NowPlayingScreen.screen.DrawObject(NowPlayingScreen.albumPlaceholder.x + 4, NowPlayingScreen.albumPlaceholder.y + 5, NowPlayingScreen.AlbumShadow)

		' 'Artist
    ' if NowPlayingScreen.artistImage <> invalid
    '   NowPlayingScreen.artistImage.Draw(NowPlayingScreen.screen)
    ' end if
    ' if NowPlayingScreen.previousArtistImage <> invalid
    '   NowPlayingScreen.previousArtistImage.Draw(NowPlayingScreen.screen)
    ' end if

    ' 'All the text
    'Artist name'
    if m.artistNameLabel <> invalid
      m.artistNameLabel.draw(m.screen)
    end if
    if m.PreviousArtistNameLabel <> invalid
      m.PreviousArtistNameLabel.draw(m.screen)
    end if

    'Song name
    if m.songNameLabel <> invalid
      m.songNameLabel.draw(m.screen)
    end if
    if m.PreviousSongNameLabel <> invalid
      m.PreviousSongNameLabel.draw(m.screen)
    end if

    'Bio
    if m.bioLabel <> invalid
      m.bioLabel.draw(m.screen)
    end if
    if m.PreviousBioLabel <> invalid
      m.PreviousBioLabel.Draw(m.screen)
    end if

		' 'Album image
    ' NowPlayingScreen.albumPlaceholder.Draw(NowPlayingScreen.screen)
    ' if NowPlayingScreen.albumImage <> invalid AND NowPlayingScreen.albumImage.image <> invalid
    '   NowPlayingScreen.albumImage.Draw(NowPlayingScreen.screen)
    ' end if
    ' if NowPlayingScreen.previousAlbumImage <> invalid
    '   NowPlayingScreen.previousAlbumImage.Draw(NowPlayingScreen.screen)
    ' end if
    ' if NowPlayingScreen.albumNameLabel <> invalid
    '   NowPlayingScreen.albumNameLabel.draw(NowPlayingScreen.screen)
    ' end if
    ' if NowPlayingScreen.PreviousAlbumNameLabel <> invalid
    '   NowPlayingScreen.PreviousAlbumNameLabel.Draw(NowPlayingScreen.screen)
    ' end if

		' 'LastFM Logo
    ' if GetGlobalAA().ActiveLastFM <> 0 THEN
		'   NowPlayingScreen.screen.DrawObject(NowPlayingScreen.screen.GetWidth() - 80 ,NowPlayingScreen.screen.GetHeight() - 60, NowPlayingScreen.lastfmlogo, &hFFFFFFFF)
    ' end if


    'Header
    headerTitleY = 28
    ' if NowPlayingScreen.song.stationDetails <> invalid AND NowPlayingScreen.song.stationDetails.Listeners <> invalid
    '   headerTitleY = 22
    ' end if
		m.screen.DrawRect(0,0, m.Width, m.HeaderHeight, GetHeaderColor())
		m.screen.DrawObject(ResolutionX(30),ResolutionY(13),m.HeaderLogo)
        
    if m.StationTitleLabel <> invalid
      m.StationTitleLabel.Draw(m.screen)
    end if

    ' Ok for help label
    m.HelpLabel.draw(m.screen)

    ' 'Possible UI Elements
    ' if NowPlayingScreen.popup <> invalid then
    '   NowPlayingScreen.popup.draw(NowPlayingScreen.screen)
    ' End if

    ' if NowPlayingScreen.OtherStationsNowPlaying <> invalid
    '   NowPlayingScreen.OtherStationsNowPlaying.Draw(NowPlayingScreen.screen)
    ' end if

		m.screen.SwapBuffers()
	end if

End Function

Function GetNowPlayingTimer()
	timer = GetGlobalAA().lookup("NowPlayingTimer")
	if timer = invalid then
		timer = CreateObject("roTimespan")
		GetGlobalAA().AddReplace("NowPlayingTimer", timer)
	endif

	return timer
End Function

' Function DrawStationDetailsLabel(NowPlayingScreen as object)
'   if NowPlayingScreen.song.stationDetails <> invalid then
'     stationListeners = NowPlayingScreen.song.stationDetails.Listeners
'     stationBitrate = NowPlayingScreen.song.stationDetails.bitrate

'     if NowPlayingScreen.song.StationDetails.updated AND stationListeners <> invalid AND stationBitrate <> invalid
'       NowPlayingScreen.stationDetailsLabel = StationDetailsLabel(stationListeners, stationBitrate)
'       NowPlayingScreen.song.StationDetails.updated = false
'     end if

'     if NowPlayingScreen.stationDetailsLabel <> invalid
'       NowPlayingScreen.stationDetailsLabel.draw(NowPlayingScreen.screen)
'     end if
'   end if
' End Function
