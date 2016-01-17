Function selection_getSomaFMStations()
  url = GetConfig().BatUtils + "somafm"
  stations = GetStationsAtUrl(url)
  m.Screen.SetContentList(1, stations)
  m.Screen.SetListVisible(1, true)
  m.SomaFMStations = stations
End Function

Function selection_getFeaturedStations()
  url = "https://s3-us-west-2.amazonaws.com/batserver-static-assets/directory/featured.json"
  stations = GetStationsAtUrl(url)
  m.Screen.SetContentList(2, stations)
  m.Screen.SetListVisible(2, true)
  m.FeaturedStations = stations
End Function

Function selection_getGabeStations()
  url = "https://s3-us-west-2.amazonaws.com/batserver-static-assets/directory/gabeFavorites.json"
  stations = GetStationsAtUrl(url)
  m.Screen.SetContentList(3, stations)
  m.Screen.SetListVisible(3, true)
  m.GabeStations = stations
End Function

Function GetStationsAtUrl(url as String) as object
  stationsKey = makemdfive(url)
  stationsJsonArray = GetStationCollection(stationsKey)
  shouldSaveStations = false

  if stationsJsonArray = invalid
    Request = GetRequest()
    Request.SetUrl(url)
    jsonString = Request.GetToString()
    stationsJsonArray = ParseJSON(jsonString)
    stationsKey = makemdfive(url)
    SaveStationCollectionJson(stationsKey, jsonString)
  end if

  stationsArray = CreateObject("roArray", stationsJsonArray.count(), true)

  for i = 0 to stationsJsonArray.Count() -1
    singleStation = stationsJsonArray[i]
    singleStationItem = CreateSong(singleStation.name, singleStation.provider, "", "mp3", "", singleStation.image)
    singleStationItem.playlist = singleStation.playlist
    ASyncGetFile(singleStation.image, "tmp:/" + makemdfive(singleStation.image))
    stationsArray.push(singleStationItem)
  end for


  return stationsArray
End Function

Function selection_showDirectoryPopup(station as object)
  Analytics = GetSession().Analytics
  Analytics.AddEvent("Directory Popup Displayed")

  port = GetPort()

  dialog = CreateObject("roMessageDialog")
  dialog.SetMessagePort(port)
  dialog.SetTitle(station.stationname)
  dialog.SetText("Add or Play this station.")

  dialog.AddButton(1, "Play")
  dialog.AddButton(2, "Add To My Stations")
  dialog.EnableBackButton(true)

  dialog.Show()

  While True
      msg = port.GetMessage()
      HandleWebEvent(msg) 'Because we created a standalone event loop I still want the web server to respond, so send over events.

      If type(msg) = "roMessageDialogEvent"
          if msg.isButtonPressed()
            updatedStation = GetDirectoryStation(station)

            if msg.GetIndex() = 2
                ' Add Station'
                stationObject = CreateObject("roAssociativeArray")
                if updatedStation.DoesExist("streamformat")
                  stationObject.format = updatedStation.streamformat
                else
                  stationObject.format = "mp3"
                end if
                stationObject.image = updatedStation.stationimage
                stationObject.name = updatedStation.stationname
                stationObject.provider = updatedStation.stationprovider
                stationObject.stream = updatedStation.feedurl
                AddStation(stationObject)
              else if msg.GetIndex() = 1
                dialog.close()

                if station.DoesExist("feedurl")
                ' Play Station
                  PlayStation(updatedStation)
                else
                  ' Parse playlist'
                  GetDirectoryStation(station)
                end if

                exit while
              end if

              dialog.ShowBusyAnimation()
              exit while

          else if msg.isScreenClosed()
              exit while
          end if
      end if
  end while

End Function

Function GetDirectoryStation(station) as Object

  ' If we can play it, then just play it'
  if station.DoesExist("feedurl") AND station.feedurl <> invalid AND station.feedurl <> ""
    PlayStation(station)
    return true
  end if

  ' Otherwise we need to download the playlist and get an audio stream from it
  if station.DoesExist("playlist") AND station.playlist <> invalid
    print "Trying to convert playlist " + station.playlist + " to an audio stream."

    Request = GetRequest()
    Request.SetUrl(station.playlist)
    playlistString = Request.GetToString()
    index = playlistString.Instr("File1=")

    ' If File= doesn't exist treat as a m3u playlist
    if index = -1
      splitStringArray = playlistString.tokenize(CHR(10))
      station.feedurl = splitStringArray[0]
      return station
    end if

    ' Otherwise parse as a pls playlist
    index = index + 6
    endOfLine = playlistString.InStr(index, CHR(10))
    numOfChars = endOfLine - index
    audiourl = playlistString.Mid(index, numOfChars)
    print "Parsed out: " + audiourl
    if audiourl <> invalid
      station.feedurl = audiourl
      return station
    end if

  end if

End Function
