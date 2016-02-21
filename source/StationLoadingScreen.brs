Function DisplayStationLoading(station as Object)
	this = {
		close: Loading_close
		stationImage: invalid
		stationName: station.stationName
		canvas: invalid
		init: initStationLoadingScreen
	}

	if station.stationImage <> invalid
		this.stationImage = "tmp:/" + makemdfive(station.StationImage)
	end if
	
	this.init()
	GetNowPlayingScreen().loadingScreen = this
	GetGlobalAA().StationLoadingScreen = this
	GetGlobalAA().IsStationLoadingDisplayed = true
	GetGlobalAA().IsStationSelectorDisplayed = false

	return this

End Function

Function initStationLoadingScreen()

    device = GetSession().deviceInfo
    width = device.GetDisplaySize().w
		headerSize = SizeOfImageAtPath("tmp:/headerImage.jpg")

		canvasItems = [
					{
						url: "tmp:/headerImage.jpg",
						TargetRect:{x:ResolutionX(0),y:ResolutionY(0),w:width,h:headerSize.height}
					},
	        {
	            url:m.stationImage
	            TargetRect:{x:ResolutionX(390),y:ResolutionY(200),w:ResolutionX(450),h:ResolutionY(350)}
	        },
	        {
	        	url:"pkg:/images/batoverlay.png"
	            TargetRect:{x:ResolutionX(420),y:ResolutionY(300),w:ResolutionX(400),h:ResolutionY(166)}
	        },
	        {
	            Text:"Please wait while we try to find some details about " + m.stationName + "."
	            TextAttrs:{Color:"#FFCCCCCC", Font:"Medium",
	            HAlign:"HCenter", VAlign:"VCenter",
	            Direction:"LeftToRight"}
	            TargetRect:{x:ResolutionX(370),y:ResolutionY(600),w:ResolutionX(500),h:ResolutionY(60)}
	        }
	    ]

	LoadingScreen = CreateObject("roImageCanvas")
	port = GetPort()
	LoadingScreen.SetMessagePort(port)

	LoadingScreen.SetLayer(0, {Color:"#FF000000", CompositionMode:"Source"})
	LoadingScreen.SetLayer(1, canvasItems)
	LoadingScreen.Show()
	m.canvas = LoadingScreen

End Function

Function Loading_close()
	print "Closing loading screen"
	GetGlobalAA().IsStationLoadingDisplayed = false
	if m.canvas <> invalid
		m.canvas.close()
		m.canvas = invalid
		m = invalid
		GetGlobalAA().StationLoadingScreen = invalid
	end if
End Function

Function HandleStationLoadingScreenEvent(msg)
	if msg.GetIndex() = 0 then
		screen = GetGlobalAA().StationLoadingScreen
		if screen <> invalid
			screen.close()
			GetGlobalAA().IsStationSelectorDisplayed = true
		end if
	end if
End Function
