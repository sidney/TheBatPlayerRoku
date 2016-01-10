Sub SetLightsToColor(rgb as Object)

	if rgb = invalid OR rgb.red = invalid
		return
	end if

	lightsArray = GetLights(false)
	ip = lightsArray.ip
	username = GetLightsUsername()

	if ip = invalid OR lightsArray.lights.count() = 0 OR username = invalid
		return
	end if

	color = HueColorConvert(rgb.red, rgb.green, rgb.blue)

	lightRequests = CreateObject("roArray", 0, true)
	GetGlobalAA().lightRequests = lightRequests

	Analytics = GetSession().Analytics
	Analytics.AddEvent("Updated Lighting For Song")

	for each light in lightsArray.lights
		url = "http://" + ip + "/api/" + username + "/lights/" + light + "/state"
	    request = CreateObject("roUrlTransfer")
	    request.RetainBodyOnError(true)
	    request.EnablePeerVerification(false)
	    request.EnableHostVerification(false)
	    request.SetRequest("PUT")
	    request.SetUrl(url)
	    port = GetPort()
	    request.SetMessagePort(port)

	    requestBody = CreateObject("roAssociativeArray")
	    requestBody.on = true
			requestBody.xy = color
	    requestBody.transitiontime = 30

	    json = FormatJson(requestBody)
			lightRequests.push(request)

		request.AsyncPostFromString(json)

	end for
End Sub


Sub GetLights(returnAsJson as Boolean) as Object
	lightsJson = RegRead("lights", "batplayer")

	if lightsJson = invalid
		lightsJson = FormatJson(CreateObject("roAssociativeArray"))
	end if

	if NOT returnAsJson then
		return ParseJSON(lightsJson)
	end if

	return lightsJson

End Sub

Sub GetLightsIp(returnAsJson as Boolean) as dynamic
	ip = RegRead("lightip", "batplayer")

	if not returnAsJson then
		return ip
	end if

	json = CreateObject("roAssociativeArray")
	json.ip = ip

	return FormatJson(json)
End Sub

Sub GetLightsUsername() as string
	lightsArray = GetLights(false)
	username = lightsArray.hueUsername

	if username = invalid
		username = "thebatplayer"
	end if

	return username
End Sub

Function ChangeBrightnessTo(brightness as Integer)
	GetSession().Lighting.Brightness.Current = brightness
	lightsArray = GetLights(false)
	ip = lightsArray.ip
	username = GetLightsUsername()

	if ip = invalid OR username = invalid
		return false
	end if

	for each light in lightsArray.lights

		url = "http://" + ip + "/api/" + username + "/lights/" + light + "/state"
	    request = CreateObject("roUrlTransfer")
	    request.RetainBodyOnError(true)
	    request.EnablePeerVerification(false)
	    request.EnableHostVerification(false)
	    request.SetRequest("PUT")
	    request.SetUrl(url)
	    port = GetGlobalAA().screenPort
	    request.SetMessagePort(port)

	    requestBody = CreateObject("roAssociativeArray")
	    requestBody.on = true
	    requestBody.bri = brightness
	    json = FormatJson(requestBody)
		request.PostFromString(json)
	end for

End Function

Function ToggleBrightnessMode(direction as String)
	lights = GetLights(false)

	if lights.count() = 0
		Analytics = GetSession().Analytics
		Analytics.AddEvent("Attempted to toggle brightness mode without bulbs configured")

		DisplayPopup("There are no Philips Hue bulbs configured.  Visit: http://" + GetSession().IPAddress + ":9999 to remedy this.",  &hb20000FF, &hBBBBBB00, 8)
		return false
	end if

	modeString = ""
	brightness = 0
	if direction = "down" then
		GetSession().Lighting.Brightness.Mode = RlMin(GetSession().Lighting.Brightness.Mode + 1, 3)
		modeString = "Brightened lighting."
	end if

	if direction = "up" then
		GetSession().Lighting.Brightness.Mode = RlMax(GetSession().Lighting.Brightness.Mode - 1, 0)
		modeString = "Dimmed lighting."
	end if

	if GetSession().Lighting.Brightness.Mode = 2 then
		GetSession().Lighting.Brightness.Minimum = GetSession().Lighting.Brightness.DefaultMinimum
		GetSession().Lighting.Brightness.Maximum = GetSession().Lighting.Brightness.DefaultMaximum
		brightness = 150
	else if GetSession().Lighting.Brightness.Mode = 1 then
		GetSession().Lighting.Brightness.Minimum = GetSession().Lighting.Brightness.DefaultMinimum - 70
		GetSession().Lighting.Brightness.Maximum = GetSession().Lighting.Brightness.DefaultMaximum  - 70
		brightness = 75
	else if GetSession().Lighting.Brightness.Mode = 3 then
		GetSession().Lighting.Brightness.Minimum = GetSession().Lighting.Brightness.DefaultMinimum + 70
		GetSession().Lighting.Brightness.Maximum = GetSession().Lighting.Brightness.DefaultMaximum  + 70
		brightness = 250
	end if

	DisplayPopup(modeString)
	ChangeBrightnessTo(brightness)

	details = CreateObject("roAssociativeArray")
	details.LightingMOde = modeString
	Analytics = GetSession().Analytics
	Analytics.AddEvent("Changed Brightness changed",details)
End Function

Function HueColorConvert(r as Integer, g as Integer, b as Integer) as Object
	normalizedRed = (r / 255)
	normalizedGreen = (g / 255)
	normalizedBlue = (b / 255)

	red = 0.0
	green = 0.0
	blue = 0.0

	if normalizedRed > 0.04045
		red = ((normalizedRed + 0.055) / (1.0 + 0.055)) ^ 2.4
	else
		red = normalizedRed / 12.92
	end if

	if normalizedGreen > 0.04045
		green = ((normalizedGreen + 0.055) / (1.0 + 0.055)) ^ 2.4
	else
		green = normalizedGreen / 12.92
	end if

	if normalizedBlue > 0.04045
		blue = ((normalizedBlue + 0.055) / (1.0 + 0.055)) ^ 2.4
	else
		blue = normalizedBlue / 12.92
	end if

	X = (red * 0.649926 + green * 0.103455 + blue * 0.197109)
  Y = (red * 0.234327 + green * 0.743075 + blue * 0.022598)
  Z = (red * 0.0000000 + green * 0.053077 + blue * 1.035763)

	Finalx = X / (X + Y + Z)
  Finaly = Y / (X + Y + Z)

	return [Finalx,Finaly]
End Function
