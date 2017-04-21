'**********************************************************
'**  Audio Player Example Application - Audio Playback
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************

' playstate
' 0 = stopped
' 1 = paused
' 2 = playing

REM ******************************************************
REM
REM AudioPlayer object init
REM
REM ******************************************************
Function AudioInit() As Object
	o = CreateObject("roAssociativeArray")

	o.isPlayState			= 0   ' Stopped
	o.setPlayState			= audioPlayer_newstate
	o.setupSong			= audioPlayer_setup
	o.clearContent			= audioPlayer_clear_content
	o.setContentList		= audioPlayer_set_content_list
	o.reset = audioPlayer_reset
	audioPlayer			= CreateObject("roAudioPlayer")
	o.port 				= GetPort()
	audioPlayer.SetMessagePort(o.port)
	o.audioPlayer			= audioPlayer
	o.failCounter = 0
	o.updateStreamUrl = audioPlayer_updateStreamUrl
	o.station = invalid
	audioPlayer.SetLoop(0)

	return o
End Function

REM ******************************************************
REM
REM Setup song
REM
REM ******************************************************
Sub audioPlayer_setup(song As string, format as string)
	' If the stream URL has "aac" in it, let's assume it's an AAC stream
	if song.InStr("aac") > -1
		format = "es.aac-adts"
	end if

	print "Setting up " + format + " stream: " + song + ""
	m.setPlayState(0)
	item = CreateObject("roAssociativeArray")
	item.Url = song
	item.StreamFormat = format
	m.station = item
	m.audioPlayer.AddHeader("Icy-MetaData", "0")
	m.audioPlayer.AddHeader("User-Agent", "The Bat Player/Roku")
	m.audioPlayer.AddContent(item)
End Sub

Sub audioPlayer_updateStreamUrl(url as String)
	print "Trying URL: " + url
	
	m.station.url = url
	m.audioPlayer.clearContent()
	m.audioPlayer.AddContent(m.station)
	m.audioPlayer.play()
end sub

Sub audioPlayer_reset()
	m.setPlayState(0)
	m.audioPlayer.stop()
	m.audioPlayer.clearContent()
End Sub

REM ******************************************************
REM
REM Play audio
REM
REM ******************************************************
Sub audioPlayer_newstate(newstate as integer)
	if newstate = m.isplaystate return	' already there

	if newstate = 0 then			' STOPPED
		m.audioPlayer.Stop()
		m.isPlayState = 0
	else if newstate = 2 then		' PLAYING
		if m.isplaystate = 0
			m.audioPlayer.play()	' STOP->START
		endif
		m.isPlayState = 2
	endif
End Sub

REM ******************************************************
REM
REM Clear content
REM
REM ******************************************************
Sub audioPlayer_clear_content()
	m.audioPlayer.ClearContent()
End Sub

REM ******************************************************
REM
REM Set content list
REM
REM ******************************************************
Sub audioPlayer_set_content_list(contentList As Object)
	m.audioPlayer.SetContentList(contentList)
End Sub
