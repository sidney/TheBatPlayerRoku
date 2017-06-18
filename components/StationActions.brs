sub PlayStation(station)
	print "PlayStation(station)"
	
	headers = createObject("roArray", 2, true)
	headers.push("Icy-MetaData:0")
	headers.push("User-Agent:The Bat Player/Roku")
	station.HttpHeaders = headers

	print "Playing: " + station.url
	
	' If the stream URL has "aac" in it, let's assume it's an AAC stream
	if station.url.InStr("aac") > -1
		format = "es.aac-adts"
		station.streamformat = format
	end if

	m.openNowPlayingWhenPlaying = true
	m.station = station
	ShowWaitingDialog(station)

	m.global.audio.content = station
	m.global.audio.seek = -1
	m.global.audio.control = "play"
	m.global.audio.ObserveField("state", "playerStateChanged")
	m.global.audio.ObserveField("errorString", "playerError")
	m.global.audio.ObserveField("statusString", "playerStatusChanged")
end sub

function playerStateChanged(event)
	state = event.getData()

	print "playerStateChanged: " + state
	
	if state = "playing" AND m.openNowPlayingWhenPlaying = true
		m.openNowPlayingWhenPlaying = false
		HideWaitingDialog()
		showNowPlayingScreen(m.station)
	end if
end function

function playerStatusChanged(event)
	if m.global.scene.dialog = invalid
		return false
	end if

	if m.waitingDialogDisplayed = invalid OR m.waitingDialogDisplayed = false
		return false
	end if

	status = event.getData()
	m.global.scene.dialog.message = CapitalizeString(status) + "..."
end function

function playerError(event)
	errorString = event.getData()
	HideWaitingDialog()

	dialog = createObject("roSGNode", "Dialog")
    dialog.title = m.station.name + " Error"
	dialog.message = errorString
	m.global.scene.dialog = dialog
end function

sub showNowPlayingScreen(station)
	m.global.station = station
end sub

sub AddStation(station)
	print "ADD STATION"
end sub

function showStationPlayDialog(station)
    m.childScreen = m.top.createChild("StationDetailPanel")
    m.childScreen.station = station
    m.childScreen.setFocus(true)
end function

function ShowWaitingDialog(station)
	dialog = createObject("roSGNode", "ProgressDialog")
    dialog.title = "Please wait while The Bat Player tries to connect to " + station.name + "..."
	m.global.scene.dialog = dialog
	m.waitingDialogDisplayed = true
end function

function HideWaitingDialog()
	if m.global.scene.dialog = invalid
		return false
	end if

	m.global.scene.dialog.close = true
	m.global.scene.dialog = invalid
	m.waitingDialogDisplayed = false
end function