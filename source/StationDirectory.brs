Function selection_getSomaFMStations()
  url = "https://s3-us-west-2.amazonaws.com/batserver-static-assets/directory/somaFMStations.json"
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
  Request = GetRequest()
  Request.SetUrl(url)
  jsonString = Request.GetToString()
  stationsJsonArray = ParseJSON(jsonString)

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
                stationObject.format = updatedStation.streamformat
                stationObject.image = updatedStation.stationimage
                stationObject.name = updatedStation.stationname
                stationObject.provider = updatedStation.stationprovider
                stationObject.stream = updatedStation.feedurl
                AddStation(stationObject)
              else if msg.GetIndex() = 1
                ' Play Station
                dialog.close()
                PlayStation(updatedStation)
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
    splitStringArray = playlistString.tokenize(CHR(10))

    audiourl = invalid

    for i = 0 to splitStringArray.Count()
      singleString = splitStringArray[i]
      if singleString <> invalid
        if singleString.Instr(0, "File1=") <> -1
          startAtCharIndex = singleString.Instr(0, "=") + 1
          audiourl = singleString.Mid(startAtCharIndex)
          station.feedurl = audiourl
          return station
        else
          audiourl = singleString
        end if
      end if
    end for
  end if

End Function
