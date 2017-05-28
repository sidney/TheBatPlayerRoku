Function GetStationsAtUrl(url as String) as object
    print "GetStationsAtUrl"
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

    return stationsJsonArray  
End Function

Function GetStationCollectionJsonFromCache() as Object
	json = RegRead("StationCategories", "Transient")

	if json = invalid
		return invalid
	end if

	return json
End Function