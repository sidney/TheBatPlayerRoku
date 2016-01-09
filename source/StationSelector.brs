Function ListStations()
  print "------ Displaying Station Selector ------"
  StationSelectionScreen = StationSelectionScreen()

End Function

Function StationSelectionScreen()

  this = {
    Stations: GetStations()
    SelectableStations: invalid
    Screen: CreateObject("roGridScreen")
    SelectedIndex: 0
    RefreshStations: selection_getStations
    Handle: selection_handle
  }

  this.Screen.SetGridStyle("two-row-flat-landscape-custom")
  this.Screen.SetDescriptionVisible(true)
  this.Screen.SetUpBehaviorAtTopRow("stop")
  this.Screen.SetBreadcrumbEnabled(false)
  this.Screen.SetLoadingPoster("pkg:/images/icon-hd.png", "pkg:/images/icon-sd.png")
  port = GetPort()
  this.Screen.SetMessagePort(port)
  this.Screen.SetupLists(1)
  this.Screen.SetListName(0, "Stations")
  this.Screen.Show()

  GetGlobalAA().IsStationSelectorDisplayed = true
  GetGlobalAA().delete("screen")
  GetGlobalAA().delete("song")
  GetGlobalAA().Delete("jsonEtag")
  GetGlobalAA().lastSongTitle = invalid

  this.Screen.SetContentList(0,this.Stations)
  GetGlobalAA().AddReplace("StationSelectionScreen", this)

  this.RefreshStations()

  HandleInternetConnectivity()

  'First launch popup
  if RegRead("initialpopupdisplayed", "batplayer") = invalid
    Analytics = GetSession().Analytics
    Analytics.AddEvent("First Session began")
    ShowConfigurationMessage(StationSelectionScreen)
  end if

  return this
End Function

Function selection_getStations()
  print "------ Updating list of stations ------"
  SelectableStations = CreateObject("roArray", m.Stations.Count(), true)

  for i = 0 to m.Stations.Count()-1

      station = m.Stations[i]
      stationObject = CreateSong(station.name,station.provider,"", station.format, station.stream, station.image)
      SelectableStations.Push(stationObject)

      'Download custom poster images
      if NOT FileExists(makemdfive(stationObject.hdposterurl))
        SyncGetFile(stationObject.hdposterurl, "tmp:/" + makemdfive(stationObject.hdposterurl))
      end if
      if NOT FileExists(makemdfive(stationObject.stationimage))
        SyncGetFile(stationObject.stationimage, "tmp:/" + makemdfive(stationObject.stationimage))
      end if
      m.Screen.SetContentList(0, SelectableStations)
      m.SelectableStations = SelectableStations
      FetchMetadataForStreamUrlAndName(station.stream, station.name, true, i)
  end for

  m.Stations = SelectableStations
End Function

Function HandleInternetConnectivity()
  internetConnection = GetSession().deviceInfo.GetLinkStatus()
  if internetConnection = false
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(GetPort())
    dialog.SetTitle("Internet Required")
    dialog.SetText("The Bat Player requires an active internet connection.  Please bring your Roku online and re-launch The Bat Player.")

    dialog.AddButton(1, "OK")
    dialog.EnableBackButton(true)
    dialog.Show()

    While True
      msg = wait(0, dialog.GetMessagePort())
      If type(msg) = "roMessageDialogEvent"
        if msg.isButtonPressed()
          if msg.GetIndex() = 1
            end
            exit while
          end if
        else if msg.isScreenClosed()
          end
          exit while
        end if
      end if
    end while

  end if

End Function

Function CreatePosterItem(id as string, desc1 as string, desc2 as string) as Object
    item = CreateObject("roAssociativeArray")
    item.ShortDescriptionLine1 = desc1
    item.ShortDescriptionLine2 = desc2
    return item
end Function

Function CreateSong(title as string, description as string, artist as string, streamformat as string, feedurl as string, imagelocation as string) as Object
    item = CreatePosterItem("", title, description)
    url = imageLocation
    item.Artist = artist
    item.Title = title    ' Song name
    item.feedurl = feedurl
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

Function StationSelectorNowPlayingTrackReceived(track as dynamic, index as dynamic)
    StationSelectionScreen = GetGlobalAA().StationSelectionScreen
    Stations = GetGlobalAA().StationSelectionScreen.SelectableStations
    Screen = GetGlobalAA().StationSelectionScreen.Screen

    if track <> invalid AND index <> invalid

      if NOT isnonemptystr(track)
        return false
      end if

      station = Stations[index]
      station.Description = track
      Screen.SetContentListSubset(0, Stations, index, 1)
    end if

End Function

Function GetStationSelectionHeader()
    print "------ Downloading header ------"
    ipAddress = GetSession().IPAddress
    text = urlescape("Configure your Bat Player at http://" + ipAddress + ":9999")
    device = GetSession().deviceInfo
    width = ToStr(device.GetDisplaySize().w)

    originalHeaderFile = "selection_bat_logo-HD.png"
    fontSize = ToStr(ResolutionX(30))
    verticalPadding = ToStr(ResolutionX(35))

    query = "?fm=jpg&q=90&txtfont=Helvetica+Neue&txtclr=aaffffff&txtalign=center&txtsize=" + fontSize + "&txtfit=max&txtpad=" + verticalPadding + "&txt=" + text + "&w=" + width

    imgixHost = GetConfig().ImgixHost
    url = imgixHost + "/" + urlescape(originalHeaderFile) + query
    print url

    SyncGetFile(url, "tmp:/headerImage.jpg", true)
    print "------ Downloading header complete------"
End Function


Function ShowConfigurationMessage(StationSelectionScreen as object)
    Analytics = GetSession().Analytics
    Analytics.AddEvent("Configuration Popup Displayed")
    RegWrite("initialpopupdisplayed", "true", "batplayer")
    port = GetPort()
    ipAddress = GetSession().IPAddress

    message = "Thanks for checking out The Bat Player.  Jump on your computer and visit http://" + ipAddress + ":9999 to customize your Bat Player experience by adding stations, enabling lighting, Last.FM, Rdio support and more."

    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)
    dialog.SetTitle("Configure Your Bat Player")
    dialog.SetText(message)

    dialog.AddButton(1, "OK")
    dialog.EnableBackButton(true)
    dialog.Show()
    While True
        msg = port.GetMessage()
        HandleWebEvent(msg) 'Because we created a standalone event loop I still want the web server to respond, so send over events.
        If type(msg) = "roMessageDialogEvent"
            if msg.isButtonPressed()
                if msg.GetIndex() = 1
                    Analytics.AddEvent("Configuration Popup Dismissed")
                    dialog.close()
                    RefreshStationScreen()
                    exit while
                end if
            else if msg.isScreenClosed()
                exit while
            end if
        end if
    end while
End Function

Function selection_handle(msg as Object)

	if GetGlobalAA().IsStationSelectorDisplayed <> true
		return false
	end if

	if msg.isListItemSelected()
		GetGlobalAA().IsStationSelectorDisplayed = false

    selectionIndex = msg.GetData()
    m.SelectedIndex = selectionIndex
    Station = m.SelectableStations[selectionIndex]
		Analytics_StationSelected(Station.stationName, Station.feedurl)

		metadataUrl = GetConfig().Batserver + "metadata/" + UrlEncode(Station.feedurl)
		print "JSON for selected station: " + metadataUrl

    DisplayStationLoading(Station)
    Show_Audio_Screen(Station)
	end if

End Function

Function RefreshStationScreen()
  StationSelectionScreen = GetGlobalAA().StationSelectionScreen
  StationSelectionScreen.Stations = GetStations()
  StationSelectionScreen.RefreshStations()
End Function
