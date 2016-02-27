Sub SetTheme()
    app = CreateObject("roAppManager")
    theme = CreateObject("roAssociativeArray")

    theme.OverhangOffsetSD_X = "0"
    theme.OverhangOffsetSD_Y = "0"

    theme.GridScreenOverhangHeightHD = "200"
    theme.GridScreenOverhangHeightSD = "150"

    theme.GridScreenDescriptionOffsetHD = "(-20,203)"
    theme.GridScreenDescriptionOffsetSD = "(20,120)"

  	theme.GridScreenDescriptionTitleColor = "#FFFFFF"
  	theme.GridScreenDescriptionSynopsisColor = "#000000"

    theme.GridScreenLogoHD = "tmp:/headerImage.jpg"
    theme.GridScreenLogoSD = "tmp:/headerImage.jpg"

    theme.GridScreenLogoOffsetHD_X = "0"
    theme.GridScreenLogoOffsetHD_Y = "0"

    theme.GridScreenBackgroundColor = "#000000"
    theme.GridScreenDescriptionImageHD = "pkg:/images/speechbubble-hd.png"
    theme.GridScreenDescriptionImageSD = "pkg:/images/speechbubble-sd.png"

    theme.PosterScreenLine1Text = "#CC0000"
    theme.PosterScreenLine2Text = "#cA6c6c"

  	theme.GridScreenFocusBorderHD = "pkg:/images/StationSelectionBorder-HD.png"
  	theme.GridScreenBorderOffsetHD = "(-5,-5)"

  	theme.GridScreenFocusBorderSD = "pkg:/images/StationSelectionBorder-SD.png"
  	theme.GridScreenBorderOffsetSD = "(-8,-5)"

    theme.BackgroundColor = "#000000"
    theme.ListItemText = "#CC0000"
    theme.ButtonMenuNormalText = "#BBBBBB"

    theme.OverhangPrimaryLogoHD = "pkg:/images/header-placeholder.jpg"
    theme.OverhangPrimaryLogoOffsetHD_Y = "0"

    app.SetTheme(theme)

End Sub

Function InitFonts()
	reg = CreateObject("roFontRegistry")
	Filesystem = CreateObject("roFilesystem")
	FontNameDir = "."
	DirectoryListing = Filesystem.GetDirectoryListing("pkg:/fonts/" + FontNameDir + "/")

	DirectoryListing.ResetIndex()
	i = DirectoryListing.GetIndex()
	while i <> invalid
		reg.Register("pkg:/fonts/" + FontNameDir + "/" + i)
		i = DirectoryListing.GetIndex()
	end while

  'print reg.GetFamilies()

  GetGlobalAA().AddReplace("FontRegistry", reg)
End Function

Function GetMediumFont() as Object
	reg = GetGlobalAA().FontRegistry
  size = 22
  deviceSize = GetSession().deviceInfo.GetDisplaySize()

  if deviceSize.W = 720
    size = 13
  end if

  Font = reg.GetFont("Lato", size, false, false)
  return Font
End Function

Function GetSongNameFont() as Object
	reg = GetGlobalAA().FontRegistry
  size = 30

  deviceSize = GetSession().deviceInfo.GetDisplaySize()

  if deviceSize.W = 720
    size = 13
  end if

  Font = reg.GetFont("Lato Light", size, false, false)
  return Font
End Function

Function GetSmallFont() as Object
	reg = GetGlobalAA().FontRegistry
  Font = reg.GetFont("Lato", ResolutionY(21), false, false)
  return Font
End Function

Function GetExtraSmallFont() as Object
	reg = GetGlobalAA().FontRegistry
  Font = reg.GetFont("Lato", ResolutionY(14), false, false)
  return Font
End Function

Function GetGenreFont() as Object
	reg = GetGlobalAA().FontRegistry
  Font = reg.GetFont("Lato", ResolutionY(19), false, false)
  return Font
End Function

Function GetLargeBoldFont() as Object
	reg = GetGlobalAA().FontRegistry
  Font = reg.GetFont("Lato Light", ResolutionY(42), true, false)
  return Font
End Function

Function GetLargeFont() as Object
	reg = GetGlobalAA().FontRegistry
  Font = reg.GetFont("Lato Light", ResolutionY(43), false, false)
  return Font
End Function

Function GetHeaderFont() as Object
	reg = GetGlobalAA().FontRegistry
  Font = reg.GetFont("Lato", ResolutionY(39), true, false)
  return Font
End Function

Function GetHeaderColor() as Integer
	return &h88090F00 + 150
End Function

Function GetBoldColorForSong(song as Object) as Integer
	return GetRegularColorForSong(song)
End Function

Function GetRegularColorForSong(song as Object) as Integer
	if NOT song.DoesExist("image") OR NOT song.image.DoesExist("color") OR NOT song.image.color.DoesExist("rgb") OR song.image.color.rgb = invalid
		return MakeARGB(250,250,250,250)
	else
	  	targetBrightness = 90

	  	red = song.image.color.rgb.red
	  	green = song.image.color.rgb.green
	  	blue = song.image.color.rgb.blue
	  	alpha = 255

	  	brightness = GetBrightnessForSong(song)

	  	brightnessOffset = targetBrightness - brightness
	  	updatedColors = AlterBrightnessForRGB(red, green, blue, brightnessOffset/3)
	  	red = updatedColors[0]
	  	green = updatedColors[1]
	  	blue = updatedColors[2]

    return AlterSaturationForRGB(red, green, blue, alpha, 1.0)

	end if
End Function

Function GetBrightnessForSong(song as Object) as Integer
	if song.brightness <> 0
		return song.brightness
	end if

	if song.DoesExist("image") AND song.image.DoesExist("color") AND song.image.color.DoesExist("rgb")
    red = song.image.color.rgb.red
    green = song.image.color.rgb.green
    blue = song.image.color.rgb.blue

    brightness = Sqr(0.299 * (red * red) + 0.587 * (green * green) + 0.114 * (blue * blue))
    'print "Text Brightness: " + Str(brightness)

		song.brightness = brightness
		return brightness
	else
		return 0
	end if
End Function

Function GetLightnessForColor(r as Integer, g as Integer, b as Integer)
  lightness = 0.2126 * r + 0.7152 * g + 0.0722 * b
  return lightness
End Function

Function GetGrungeColorOffsetForColor(r as Integer, g as Integer, b as Integer) as Double
  if r > 200 AND g > 200 AND b > 2400
    return -100
  end if

  if r < 30 AND g < 30 AND b < 30
    return 100
  end if

  lightness = GetLightnessForColor(r, g, b)

  if lightness < 50
    return 40
  else
    return -40
  end if

  return 0
End Function

Function GetDropShadowColorForSong(song as Object) as integer
	return &h000000CC
End Function

Sub CreateOverlayColor(song) as integer
	if song.DoesExist("image") AND song.image.DoesExist("color") AND song.image.color.DoesExist("rgb") AND song.image.color.rgb <> invalid
    alpha = OpacityForSong(song)
		color = MakeARGB(song.image.color.rgb.red, song.image.color.rgb.green, song.image.color.rgb.blue, alpha)
	else
		color = 0
	end if
  return color
End Sub

Function OpacityForSong(song) as integer
  alpha = 100

	if song.DoesExist("image") AND song.image.DoesExist("color") AND song.image.color.DoesExist("rgb") AND song.image.color.rgb <> invalid
    brightness = Sqr(0.299 * (song.image.color.rgb.red * song.image.color.rgb.red) + 0.587 * (song.image.color.rgb.green * song.image.color.rgb.green) + 0.114 * (song.image.color.rgb.blue * song.image.color.rgb.blue))
    targetBrightness = 80
    difference = targetBrightness / brightness
    baseAlpha = 100
    alpha = RlMin(baseAlpha * difference, targetBrightness)
	end if
  return alpha
End Function

Sub CreateAlbumOverlayColor(song) as integer
  if song.DoesExist("image") AND song.image.DoesExist("color") AND song.image.color.DoesExist("rgb") AND song.image.color.rgb <> invalid
    alpha = 30
    color = MakeARGB(song.image.color.rgb.red, song.image.color.rgb.green, song.image.color.rgb.blue, alpha)
  else
    color = 0
  end if
  return color
End Sub

Function AlterSaturationForRGB(red as Integer, green as Integer, blue as Integer, alpha as integer, amount as Integer) as Double
	gray = (red + green + blue) / 3

	R = RlMax(0,RlMin(red * amount + gray * (1 - amount), alpha))
	G = RlMax(0,RlMin(green * amount + gray * (1 - amount), alpha))
	B = RlMax(0,RlMin(blue * amount + gray * (1 - amount), alpha))

	return MakeARGB(R,G,B,alpha)
end Function

Function AlterBrightnessForRGB(red as Integer, green as Integer, blue as Integer, amount as Double) as Object
	red = red + amount
	green = green + amount
	blue = blue + amount

	updatedColors = CreateObject("roArray", 3, false)
	updatedColors[0] = RlMax(0, RlMin(red, 255))
	updatedColors[1] = RlMax(0, RlMin(green, 255))
	updatedColors[2] = RlMax(0, RlMin(blue, 255))
	return updatedColors
End Function

Function MakeARGB(r As integer, g As integer, b As integer, alpha as integer) As integer
  return r*256*256*256 + g*256*256 + b*256 + alpha
End Function
