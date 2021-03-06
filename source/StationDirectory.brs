Function selection_getSomaFMStations()
  url = GetConfig().BatUtils + "somafm"
  stations = GetStationsAtUrl(url)
  m.Screen.SetContentList(4, stations)
  m.Screen.SetListVisible(4, true)
  m.SomaFMStations = stations
End Function

Function selection_getFeaturedStations()
  url = GetConfig().BatUtils + "featured"
  stations = GetStationsAtUrl(url)
  m.Screen.SetContentList(1, stations)
  m.Screen.SetListVisible(1, true)
  m.FeaturedStations = stations
End Function

Function selection_getGabeStations()
  url = GetConfig().BatUtils + "gabeFavorites"
  stations = GetStationsAtUrl(url)
  m.Screen.SetContentList(5, stations)
  m.Screen.SetListVisible(5, true)
  m.GabeStations = stations
End Function

Function selection_getDashStations()
  url = GetConfig().BatUtils + "dashradio"
  stations = GetStationsAtUrl(url)
  m.Screen.SetContentList(3, stations)
  m.Screen.SetListVisible(3, true)
  m.DashStations = stations
End Function

Function selection_getLongtailStations()
  url = "https://longtail.fm/api/external/stations"
  stations = GetStationsAtUrl(url)
  m.Screen.SetContentList(2, stations)
  m.Screen.SetListVisible(2, true)
  m.LongtailStations = stations
End Function

Function selection_setupBrowse()
  itemsArray = CreateObject("roArray", 2, true)

  browseItem = CreateObject("roAssociativeArray")
  browseItem.name = "Browse"
  browseItem.hdposterurl = "pkg:/images/SearchIcon-HD.png"
  browseItem.sdposterurl = "pkg:/images/SearchIcon-SD.png"
  itemsArray.push(browseItem)

  searchItem = CreateObject("roAssociativeArray")
  searchItem.name = "Search"
  searchItem.hdposterurl = "pkg:/images/BrowseIcon-HD.png"
  searchItem.sdposterurl = "pkg:/images/BrowseIcon-SD.png"
  itemsArray.push(searchItem)

  m.Screen.SetContentList(6, itemsArray)
End Function

Function GetStationsAtUrl(url as String) as object
  stationsKey = makemdfive(url)
  stationsJsonArray = GetStationCollection(stationsKey)

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

    stream = ""
    if singleStation.DoesExist("stream")
      stream = singleStation.stream
    end if

    image = "pkg:/images/album-placeholder.png"
    if singleStation.DoesExist("image")
      image = singleStation.image
    end if

    format = "mp3"
    if singleStation.DoesExist("format")
      format = singleStation.format
    end if

    provider = singleStation.provider
    if singleStation.provider = invalid
      provider = singleStation.name
    end if

    singleStationItem = CreateSong(singleStation.name, provider, "", format, stream, image)
    singleStationItem.provider = singleStation.stationProvider
    singleStationItem.playlist = singleStation.playlist
    singleStationItem.description = singleStation.description

    ASyncGetFile(singleStation.image, "tmp:/" + makemdfive(singleStation.image))
    stationsArray.push(singleStationItem)
  end for

  return stationsArray
End Function

Function selection_showDirectoryPopup(station as object)
  if station.image <> invalid
    ASyncGetFile(station.hdposterurl, "tmp:/" + makemdfive(station.hdposterurl))
  end if

  Analytics = GetSession().Analytics
  Analytics.AddEvent("Directory Popup Displayed")

  port = GetPort()

  dialog = CreateObject("roMessageDialog")
  dialog.SetMessagePort(port)
  dialog.SetTitle(station.stationname)

  text = "Add or Play this station."
  if station.DoesExist("description") AND station.description <> "" AND station.description <> invalid
    text = station.description
  end if

  dialog.SetText(text)

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

                if station.DoesExist("feedurl") AND station.feedurl <> invalid AND station.feedurl <> ""
                ' Play Station
                  PlayStation(updatedStation)
                else if station.DoesExist("playlist") AND station.playlist <> invalid AND station.playlist <> ""
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
      audiourl = splitStringArray[0]
      if audiourl = invalid
        return false
      end if

      audiourl = audiourl.trim()

      print "Parsed out: " + audiourl

      station.feedurl = audiourl
      return station
    end if

    ' Otherwise parse as a pls playlist
    index = index + 6
    endOfLine = playlistString.InStr(index, CHR(10))
    numOfChars = endOfLine - index
    audiourl = playlistString.Mid(index, numOfChars)
    audiourl = audiourl.trim()

    print "Parsed out: " + audiourl
    if audiourl <> invalid
      station.feedurl = audiourl
      return station
    end if

  end if
End Function

Function NavigateToBrowse()
  Analytics = GetSession().Analytics
  Analytics.AddEvent("Viewed Browse Screen")

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
  Analytics = GetSession().Analytics
  Analytics.AddEvent("Viewed Browse Screen Category")

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

        image = "pkg:/images/album-placeholder.png"
        if station.DoesExist("image") AND station.image <> invalid
          image = station.image
        end if

        stationObject = CreateSong(station.title, "", "", station.StreamFormat, "", image)
        stationObject.feedurl = station.stream
        stationObject.stationProvider = station.title

        selection_showDirectoryPopup(stationObject)

      else if msg.isScreenClosed()
          print "screen closed"
          GetGlobalAA().CategoryScreen = invalid
          exit while

      end if
    end if
  end while
End Function

Function NavigateToSearchResults(stations as Object)
  Analytics = GetSession().Analytics
  Analytics.AddEvent("Viewed Search Results")

  screen = CreateObject("roListScreen")
  screen.SetTitle("Search Results")
  port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)
  screen.SetContent(stations)
  screen.show()

  while True
    msg = wait(0, screen.GetMessagePort())

    if type(msg) = "roListScreenEvent"
      if msg.isListItemSelected()
        index = msg.GetIndex()
        station = stations[index]

        if station.image = invalid
          station.image = GetConfig().BatUtils + "imageSearch?query=" + urlencode(station.title) + "&display=true"
        end if

        stationObject = CreateSong(station.title, "", "", station.StreamFormat, "", "")
        stationObject.playlist = station.playlist
        stationObject.stationProvider = station.title

        selection_showDirectoryPopup(stationObject)
        screen.close()

        SearchScreen = GetGlobalAA().SearchScreen
        if SearchScreen <> invalid
          SearchScreen.close()
        end if

      else if msg.isScreenClosed()
          print "screen closed"
          GetGlobalAA().CategoryScreen = invalid
          exit while

      end if
    end if
  end while

End Function

Function NavigateToSearch()
  Analytics = GetSession().Analytics
  Analytics.AddEvent("Viewed Search Screen")

  results = CreateObject("roArray", 1, true)

  screen = CreateObject("roSearchScreen")
  screen.SetBreadcrumbText("", "Search")
  screen.SetClearButtonEnabled(false)
  screen.SetEmptySearchTermsText("Search for stations")
  screen.SetSearchTermHeaderText("Search:")
  screen.SetSearchButtonText("Search")

  screen.AddSearchTerm("rock")
  screen.AddSearchTerm("jazz")
  screen.AddSearchTerm("hip hop")
  screen.AddSearchTerm("Radio Paradise")
  screen.AddSearchTerm("goth")
  screen.AddSearchTerm("1.fm")
  screen.AddSearchTerm("alternative")
  screen.AddSearchTerm("80s")
  screen.AddSearchTerm("new wave")

  port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)
  GetGlobalAA().SearchScreen = screen

  screen.show()
  done = false

    while done = false
      msg = wait(0, screen.GetMessagePort())
      if type(msg) = "roSearchScreenEvent"
        if msg.isScreenClosed()
            print "screen closed"
            done = true

        else if msg.isPartialResult()
          query = msg.GetMessage()

          else if msg.isFullResult()
          query = msg.GetMessage()
          results = GetSearchResults(query)
          'Navigate to full list of results
          NavigateToSearchResults(results)
          else
              print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
          endif
      endif
    endwhile
End Function

Function FindStationInArrayWithName(name, stationArray) as Object
  For Each station in stationArray
    if station.stationname = name
      return station
    end if
  End For

  return invalid
End Function

Function GetSearchResults(query) as Object
  if query.Len() < 3
    return false
  end if

  print "Searching: " + query
  query = urlencode(query)
  url = GetConfig().BatUtils + "jsonSearch?search=" + query

  Request = GetRequest()
  Request.SetUrl(url)
  jsonString = Request.GetToString()
  searchResults = ParseJSON(jsonString)
  results = CreateObject("roArray", 1, true)

  For Each singleStation in searchResults
    encodedSearch = urlencode(singleStation.name)
    image = GetConfig().BatUtils + "imageSearch?query=" + encodedSearch + "&display=true"

    nowPlaying = ""
    if singleStation.DoesExist("nowPlaying") AND singleStation.nowPlaying <> invalid
      nowPlaying = singleStation.nowPlaying
    end if

    singleStationItem = CreateSong(singleStation.name, nowPlaying, "", singleStation.codec, "", image)
    singleStationItem.playlist = singleStation.playlist

    if singleStation.codec = "audio/mpeg"
      singleStationItem.streamformat = "mp3"
    else
      singleStationItem.streamformat = "es.aac-adts"
    end if

    results.push(singleStationItem)
  End For

  return results
End Function

Function GetBrowseCategories() as Object
  categoriesJsonString = GetStationCollectionJsonFromCache()
  if categoriesJsonString = invalid
    print "Categories not in cache.  Fetching."
    url = GetConfig().BatUtils + "categories"
    Request = GetRequest()
    Request.SetUrl(url)
    categoriesJsonString = Request.GetToString()
    RegWrite("StationCategories", categoriesJsonString, "Transient")

  end if

  categoriesArray = ParseJSON(categoriesJsonString)
  categories = CreateObject("roArray", 1, true)

  For Each category in categoriesArray
    item = CreateObject("roAssociativeArray")
    item.title = category.name
    item.categoryId = category.id
    categories.push(item)
  End For

  return categories
End Function

Function GetStationCollectionJsonFromCache() as Object
	json = RegRead("StationCategories", "Transient")

	if json = invalid
		return invalid
	end if

	return json
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

    image = "pkg:/images/album-placeholder.png"
    if station.DoesExist("image") AND station.image <> invalid
      image = station.image
    else
      encodedSearch = urlencode(station.name)
      image = GetConfig().BatUtils + "imageSearch?query=" + encodedSearch + "&display=true"
    end if

    item = CreateSong(station.name, "", "", "mp3", "", image)

    item.title = station.name
    item.stationProvider = station.name
    item.category = station.category
    item.stream = station.stream
    item.image = image
    item.url = image
    item.sdposterurl = image
    item.hdposterurl = image
    item.StreamBitrates = [station.bitrate]
    item.StreamFormat = "mp3"
    item.Categories = [station.category]

    stations.push(item)
  End For

  return stations
End Function
