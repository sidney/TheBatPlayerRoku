sub PlayStation(station)
	headers = createObject("roArray", 2, true)
	headers.push("Icy-MetaData:0")
	headers.push("User-Agent:The Bat Player/Roku")
	station.HttpHeaders = headers

	' If the stream URL has "aac" in it, let's assume it's an AAC stream
	if station.url.InStr("aac") > -1
		format = "es.aac-adts"
		station.streamformat = format
	end if

	print station
	m.global.audio.content = station
	m.global.audio.control = "play"
	'ShowWaitingDialog(station)

	showNowPlayingScreen(station)
end sub

sub showNowPlayingScreen(station)
	m.global.station = station
end sub

sub AddStation(station)
	print "ADD STATION"
end sub

sub ShowWaitingDialog(station)
	m.global.observeField("song", "HideWaitingDialog")

	waitingDialog = createObject("roSGNode", "ProgressDialog")
    waitingDialog.title = "Please wait while The Bat Player tries to find what is playing on " + station.name + "..."

	if m.top.getParent().DoesExist("dialog")
		'm.top.getParent().dialog = m.waitingDialog
	else
    	m.top.getParent().getParent().getParent().dialog = waitingDialog
	end if

	'm.global.waitingDialog = waitingDialog

	print m.global
end sub

function HideWiatingDialog()
	print "HideWiatingDialog()"
	'm.global.waitingDialog.close = true
	'm.global.waitingDialog = invalid
end function
