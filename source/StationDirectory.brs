Function selection_getSomaFMStations()
  url = GetConfig().BatUtils + "somafm"
  stations = GetStationsAtUrl(url)
  m.Screen.SetContentList(2, stations)
  m.Screen.SetListVisible(2, true)
  m.SomaFMStations = stations
End Function

Function selection_getFeaturedStations()
  url = GetConfig().BatUtils + "featured"
  stations = GetStationsAtUrl(url)
  m.Screen.SetContentList(3, stations)
  m.Screen.SetListVisible(3, true)
  m.FeaturedStations = stations
End Function

Function selection_getGabeStations()
  url = GetConfig().BatUtils + "gabeFavorites"
  stations = GetStationsAtUrl(url)
  m.Screen.SetContentList(4, stations)
  m.Screen.SetListVisible(4, true)
  m.GabeStations = stations
End Function

Function selection_setupBrowse()
  itemsArray = CreateObject("roArray", 2, true)

  browseItem = CreateObject("roAssociativeArray")
  browseItem.name = "Browse"
  itemsArray.push(browseItem)

  searchItem = CreateObject("roAssociativeArray")
  searchItem.name = "Search"
  searchItem.hdposter = "pkg:/images/searchIcon.png"
  searchItem.sdposter = "pkg:/images/searchIcon.png"

  itemsArray.push(searchItem)

  m.Screen.SetContentList(1, itemsArray)
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
  if station.image <> invalid
    ASyncGetFile(station.image, "tmp:/" + makemdfive(station.image))
  end if

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

                BrowseScreen = GetGlobalAA().BrowseScreen
                if BrowseScreen <> invalid
                  BrowseScreen.close()
                end if

                CategoryScreen = GetGlobalAA().CategoryScreen
                if CategoryScreen <> invalid
                  CategoryScreen.close()
                end if

                exit while
              end if

              exit while

          else if msg.isScreenClosed()
              exit while
          end if
      end if
  end while

End Function

Function GetDirectoryStation(station) as Object

  ' If we can play it, then just return
  if station.DoesExist("feedurl") AND station.feedurl <> invalid AND station.feedurl <> ""
    return station
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

Function NavigateToBrowse()
  screen = CreateObject("roListScreen")
  screen.SetTitle("Browse Stations")

  port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)

  categories = GetBrowseCategories()
  screen.SetContent(categories)

  screen.show()

  GetGlobalAA().BrowseScreen = screen

  while True
    msg = wait(0, screen.GetMessagePort())

    if type(msg) = "roListScreenEvent"

      if msg.isListItemSelected()
        index = msg.GetIndex()
        category = categories[index]
        NavigateToBrowseCategory(category.categoryId)

      else if msg.isScreenClosed()
          print "screen closed"
          GetGlobalAA().BrowseScreen = invalid
          exit while
      end if

    end if

  end while
End Function

Function NavigateToBrowseCategory(category as Integer)
  screen = CreateObject("roListScreen")
  screen.SetTitle("Browse Stations")

  port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)
  GetGlobalAA().CategoryScreen = screen

  stations = GetStationsForCategory(category)
  screen.SetContent(stations)

  screen.show()

  done = false

  while True
    msg = wait(0, screen.GetMessagePort())

    if type(msg) = "roListScreenEvent"
      if msg.isListItemSelected()
        index = msg.GetIndex()
        station = stations[index]
        stationObject = CreateSong(station.title, station.description, "", station.StreamFormat, "", station.image)
        stationObject.feedurl = station.stream

        selection_showDirectoryPopup(stationObject)

      else if msg.isScreenClosed()
          print "screen closed"
          GetGlobalAA().CategoryScreen = invalid
          exit while

      end if


    end if

  end while

End Function

Function NavigateToSearch()
  displayHistory = false

  history = CreateObject("roArray", 1, true)
  screen = CreateObject("roSearchScreen")
  screen.SetBreadcrumbText("", "search")

  port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)

  screen.show()
  done = false

    while done = false
      msg = wait(0, screen.GetMessagePort())
      if type(msg) = "roSearchScreenEvent"
        if msg.isScreenClosed()
            print "screen closed"
            done = true

        else if msg.isCleared()
          print "search terms cleared"
          history.Clear()

        else if msg.isPartialResult()
          print "partial search: "; msg.GetMessage()
          if not displayHistory
              screen.SetSearchTerms((msg.GetMessage()))
          endif

          else if msg.isFullResult()
              print "full search: "; msg.GetMessage()
              history.Push(msg.GetMessage())
              if displayHistory
                  screen.AddSearchTerm(msg.GetMessage())
              end if
              'uncomment to exit the screen after a full search result:
              'done = true
          else
              print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
          endif
      endif
    endwhile
End Function

Function PerformSearch(query) as Object
  url = GetConfig().BatUtils + "keywordSearch?search=" + query
End Function

Function GetBrowseCategories() as Object
  url = GetConfig().BatUtils + "categories"
  Request = GetRequest()
  Request.SetUrl(url)
  jsonString = Request.GetToString()
  categoriesArray = ParseJSON(jsonString)

  categories = CreateObject("roArray", 1, true)

  For Each category in categoriesArray
    item = CreateObject("roAssociativeArray")
    item.title = category.name
    item.categoryId = category.id
    categories.push(item)
  End For

  return categories
End Function

Function GetStationsForCategory(category as Integer) as Object
  url = GetConfig().BatUtils + "category?categoryId=" + ToStr(category)
  Request = GetRequest()
  Request.SetUrl(url)
  jsonString = Request.GetToString()
  stationsArray = ParseJSON(jsonString)

  stations = CreateObject("roArray", 1, true)

  For Each station in stationsArray
    item = CreateObject("roAssociativeArray")

    item.title = station.name
    item.provider = station.name
    item.category = station.category
    item.stream = station.stream
    item.image = station.image
    item.url = station.image
    item.sdposterurl = station.image
    item.hdposterurl = station.image
    item.StreamBitrates = [station.bitrate]
    item.StreamFormat = "mp3"
    item.Description = station.category
    item.Categories = [station.category]

    stations.push(item)
  End For

  return stations
End Function
