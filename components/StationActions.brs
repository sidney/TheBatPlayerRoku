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

	m.global.audio.content = station
	m.global.audio.control = "play"
	ShowWaitingDialog(station)

	showNowPlayingScreen(station)
end sub

sub showNowPlayingScreen(station)
	m.global.station = station
end sub

sub AddStation(station)
	print "ADD STATION"
end sub

sub ShowWaitingDialog(station)
	print "ShowWaitingDialog(station)"
	m.waitingDialog = createObject("roSGNode", "ProgressDialog")
    m.waitingDialog.title = "Please wait while The Bat Player tries to find what is playing on " + station.name + "..."

	if (m.top.getParent().dialog <> invalid)
		'm.top.getParent().dialog = m.waitingDialog
	else
    	m.top.getParent().getParent().getParent().dialog = m.waitingDialog
	end if

end sub
