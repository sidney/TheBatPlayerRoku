function audioplayer_stateChanged(event)
    state = event.getData()
    
    print "Audio Player: " + state + ". " + m.top.content.url

    if state = "error"
        audioplayer_handleError()
    end if

    if state = "playing" AND m.timer <> invalid
        m.timer.control = "stop"
        m.timer = invalid
    end if

    m.top.statusString = state
end function

function audioplayer_controlChanged(event)
    control = event.getData()
    print "Audio Player Control: " + control

    if control <> "play"
        return false
    end if

    startTimer()
end function

function audioplayer_reportStatus(status)
    m.top.statusString = status
end function

function audioplayer_reportError(error)
    m.top.errorString = error
end function

function audioplayer_handleError()
    print "Audio Player Error " + m.top.errorCode.toStr() + ": " + m.top.errorMsg.toStr()

    m.errorCounter = m.errorCounter + 1

    if m.errorCounter > m.maxErrors
        print "Audio Player Error: Maximum number of errors exceeded."
        
        m.timer.control = "stop"
        m.top.control = "stop"
        m.timer = invalid

        audioplayer_reportError("Unable to play station.  Double check the stream URL.")
        return false
    end if
    
    content = m.top.content

    ' If there's no error code then let's make some guesses
    if m.top.errorCode = 0
        newCodec = "es.aac-adts"
        content.StreamFormat = newCodec

        print "Audio Player: Changing codec to " + newCodec + " and restarting stream."
        audioplayer_reportStatus("Retrying as AAC stream")

        m.top.content = content
        audioplayer_restartPlayer()
        startTimer()

        return false    
    end if

    ' If we got data back but it's unplayable try a different codec
    if m.top.errorCode = -5
        newCodec = "es.aac-adts"
        content.StreamFormat = newCodec

        print "Audio Player: Changing codec to " + newCodec + " and restarting stream."
        audioplayer_reportStatus("Retrying as AAC stream")

        m.top.content = content
        audioplayer_restartPlayer()
        startTimer()

        return false
    end if

    ' Bad url?
    if m.top.errorCode = -3 OR m.top.errorCode = -1
        newStream = SanitizeStreamUrl(m.top.content.url)
        print "Audio Player: Changing stream URL to " + newStream + " and restarting stream."
        audioplayer_reportStatus("Locating playable stream")

        content.url = newStream
        m.top.content = content
        audioplayer_restartPlayer()
        startTimer()

        return false      
    end if

    print "Audio Player: Cannot handle error " + m.top.errorCode
end function

function audioplayer_timeoutTimerFired(event)
    print "Audio Player: Playback Timeout"
    audioplayer_reportError("Timed out.  Retrying.")
    audioplayer_handleError()
    m.timer = invalid
end function

function startTimer()
    m.timer = createObject("roSGNode", "Timer")
    m.timer.reapeat = false
    m.timer.duration = 7
    m.timer.ObserveField("fire", "audioplayer_timeoutTimerFired")
    m.timer.control = "start"
end function

function audioplayer_restartPlayer()
    m.top.seek = -1
    m.top.control = "play"
end function