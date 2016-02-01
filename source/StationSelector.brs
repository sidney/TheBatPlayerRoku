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
    RefreshNowPlayingData: selection_refreshNowPlayingData

    SomaFMStations: invalid
    GetSomaFMStations: selection_getSomaFMStations
    FetchingSomaFmStations: false

    FeaturedStations: invalid
    GetFeaturedStations: selection_getFeaturedStations
    FetchingFeturedStations: false

    GabeStations: invalid
    GetGabeStations: selection_getGabeStations
    FetchingGabeStations: false

    SetupBrowse: selection_setupBrowse

    DisplayStationPopup: selection_showDirectoryPopup
    Handle: selection_handle
  }

  this.Screen.SetGridStyle("four-column-flat-landscape")
  this.Screen.SetLoadingPoster("pkg:/images/icon-hd.png", "pkg:/images/icon-sd.png")

  this.Screen.SetupLists(5)
  this.Screen.SetListName(0, "Your Stations")
  this.Screen.SetListName(1, "Browse Stations")
  this.Screen.SetListName(2, "Stations from SomaFM")
  this.Screen.SetListName(3, "Featured Stations")
  this.Screen.SetListName(4, "Gabe's Current Favorites")

  this.Screen.SetListVisible(0, true)
  this.Screen.SetListVisible(1, true)
  this.Screen.SetListVisible(2, false)
  this.Screen.SetListVisible(3, false)
  this.Screen.SetListVisible(4, false)

  port = GetPort()
  this.Screen.SetMessagePort(port)

  GetGlobalAA().IsStationSelectorDisplayed = true
  GetGlobalAA().delete("screen")
  GetGlobalAA().delete("song")
  GetGlobalAA().Delete("jsonEtag")
  GetGlobalAA().lastSongTitle = invalid

  GetGlobalAA().AddReplace("StationSelectionScreen", this)

  this.setupBrowse()
  this.Screen.Show()
  this.RefreshStations()

  'First launch popup
  if RegRead("initialpopupdisplayed", "batplayer") = invalid
    Analytics = GetSession().Analytics
    Analytics.AddEvent("First Session began")
    ShowConfigurationMessage(StationSelectionScreen)
  end if

  this.GetSomaFMStations()
  HandleInternetConnectivity()

  return this
End Function

Function selection_getStations()
  print "------ Updating list of stations ------"
  SelectableStations = CreateObject("roArray", m.Stations.Count(), true)

  for i = 0 to m.Stations.Count()-1

      station = m.Stations[i]
      if station.DoesExist("stream") AND station.stream <> ""
        stationObject = CreateSong(station.name,station.provider,"", station.format, station.stream, station.image)
        SelectableStations.Push(stationObject)
        FetchMetadataForStreamUrlAndName(station.stream, station.name, true, i)

        'Download custom poster images
        if NOT FileExists(makemdfive(stationObject.hdposterurl))
          ASyncGetFile(stationObject.hdposterurl, "tmp:/" + makemdfive(stationObject.hdposterurl))
        end if
        if NOT FileExists(makemdfive(stationObject.stationimage))
          ASyncGetFile(stationObject.stationimage, "tmp:/" + makemdfive(stationObject.stationimage))
        end if
      end if

      'Download custom poster images
      if NOT FileExists(makemdfive(stationObject.hdposterurl))
        ASyncGetFile(stationObject.hdposterurl, "tmp:/" + makemdfive(stationObject.hdposterurl))
      end if
      if NOT FileExists(makemdfive(stationObject.stationimage))
        ASyncGetFile(stationObject.stationimage, "tmp:/" + makemdfive(stationObject.stationimage))
      end if
      m.Screen.SetContentList(0, SelectableStations)
      m.SelectableStations = SelectableStations
      FetchMetadataForStreamUrlAndName(station.stream, station.name, true, i)
  end for

  m.Screen.SetContentList(0, SelectableStations)
  m.SelectableStations = SelectableStations
  m.Screen.SetListVisible(0, true)
  m.Stations = SelectableStations
End Function

Function selection_refreshNowPlayingData()
  for i = 0 to m.Stations.Count()-1
    station = m.Stations[i]
    if station.DoesExist("feedurl") AND station.feedurl <> ""
      FetchMetadataForStreamUrlAndName(station.feedurl, station.stationname, true, i)
    end if
  end for
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

Function ShowConfigurationMessage(StationSelectionScreen as object)
    Analytics = GetSession().Analytics
    Analytics.AddEvent("Configuration Popup Displayed")
    RegWrite("initialpopupdisplayed", "true", "batplayer")
    port = GetPort()
    ipAddress = GetSession().IPAddress

    message = "Thanks for checking out The Bat Player.  Jump on your computer and visit http://" + ipAddress + ":9999 to customize your Bat Player experience by adding stations, enabling lighting and setting up Last.FM support.  A select number of stations are also featured in the Stations directory in the channel for you to check out."

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

  row = msg.GetIndex()
  item = msg.GetData()

	if msg.isListItemSelected()
    if row = 0
		  GetGlobalAA().IsStationSelectorDisplayed = false

      m.SelectedIndex = item
      Station = m.SelectableStations[item]
      PlayStation(Station)
    else if row = 1
      if item = 0
        ' Go to search
        NavigateToSearch()
      else if item = 1
        ' Go to browse
        NavigateToBrowse()
      end if
    else
      station = invalid

      if row = 2
        station = m.SomaFMStations[item]
      else if row = 3
        station = m.FeaturedStations[item]
      else if row = 4
        station = m.GabeStations[item]
      end if

      if station <> invalid
        m.DisplayStationPopup(station)
      end if

    end if
  else if msg.isListItemFocused()
    ' Download the content for the next row in the directory'
    if row = 1
      m.Screen.SetDescriptionVisible(false)
    else
      m.Screen.SetDescriptionVisible(true)
    end if

    if row = 2 AND m.FeaturedStations = invalid AND m.FetchingFeturedStations = false
      m.FetchingFeturedStations = true
      m.GetFeaturedStations()
    else if row = 3 AND m.GabeStations = invalid AND m.FetchingGabeStations = false
      m.FetchingGabeStations = true
      m.GetGabeStations()
    end if

	end if

End Function

Function RefreshStationScreen()
  StationSelectionScreen = GetGlobalAA().StationSelectionScreen
  StationSelectionScreen.Stations = GetStations()
  StationSelectionScreen.RefreshStations()
End Function
