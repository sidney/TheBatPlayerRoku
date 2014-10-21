Function AsyncGetFile(url as string, filepath as string)
  if url <> invalid AND filepath <> invalid AND url <> "" then
    'Do we already have this file?
    FileSystem = CreateObject("roFileSystem")
    if FileSystem.Exists(filepath) = true then
      'We already have this file
      ' print "*** It seems we already have file: " +url
    else 
      Request = CreateObject("roUrlTransfer")
      Request.SetUrl(url)
      Request.SetPort(GetPort())
      if Request.AsyncGetToFile(filepath) then
        Identity = str(Request.GetIdentity())
        ' print "Started download of: " + url + " to " + filepath ". " + Identity
        GetGlobalAA().AddReplace(Identity, Request)
      else
        BatLog("***** Failure BEGINNING download.", "error")
      end if
    end if
  end if
End Function

Function IsDownloading(Identity as String) as Boolean
    Key = Identity
    return (GetGlobalAA().DoesExist(Key))
End Function

Function FileExists(Filename as String) as Boolean
    FileSystem = CreateObject("roFileSystem")
    return FileSystem.Exists("tmp:/" + Filename)
End Function

Sub makemdfive(stringData as string) as string
	ba1 = CreateObject("roByteArray")
	ba2 = CreateObject("roByteArray")
	ba2.FromAsciiString(stringData)
	digest = CreateObject("roEVPDigest")
	digest.setup("md5")
	digest.Update(ba1)
	digest.Update(ba2)
	result = digest.Final()
	return result
End Sub

function HexToInteger3(hex_in)
	if hex_in = invalid then
		return &hFFFFFFFF
	end if

    bArr = createobject("roByteArray")
    if len(hex_in) mod 2 > 0 
        'fix for fromHexString() malicious silent failure on odd length
        hex_in = "0" + hex_in
    end if
    bArr.fromHexString(hex_in)    
    out = 0
    for i = 0 to bArr.count()-1
        out = 256 * out + bArr[i]
    end for

    return out
end function

function decToHex (dec as integer) as string
   hexTab = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
   hex = ""
   while dec > 0
      hex = hexTab [dec mod 16] + hex
      dec = dec / 16
   end while
   if hex = "" return "0" else return hex
end function

function rgbToInt(red as double, green as double, blue as double)
  color = (blue * 65536) + (green * 256) + red + 255

  print "Converting red: " + str(red) + " Green: " + str(green) + " Blue: " + str(blue) + " to " + str(color)
  return color
end function

Sub AppTheme() as Object
  theme = GetGlobalAA().Lookup("theme")
  if theme = invalid then
    theme = CreateObject("roAssociativeArray")
  end if
  
  return theme
End Sub

Function GetReverseColorForRGB(Red as Integer, Green as Integer, Blue as Integer) as Integer
  Contrast = SQR(Red * Red * 0.241 + Green * Green * 0.691 + Blue * Blue * 0.068)

  if Contrast > 90 then
    print "Dark dropshadow " + str(Contrast)
    return int(&h00000000 + 0)
  else if Contrast < 40 then
    print "Light dropshadow " + str(Contrast)
    return int(&hDDDDDD00 + 35)
  else if Contrast > 50 AND Contrast < 90
    print "Medium light dropshadow"
    return int(&h99999900 + 45)
  else
    print "No dropshadow " + str(Contrast)
    return int(&h00000000)
  end if
End Function

Function GetIPAddress() as String
  IPs = createObject("roDeviceInfo").getIpAddrs()
  IPs.reset()
  ip = IPs[IPs.next()]
  return ip
End Function

Function DeleteRegistry()
  myreg = CreateObject("roRegistry")
  reglist = myreg.GetSectionList()
  print reglist.Count();" sections"
  for each sect in reglist
     print sect
     myreg.Delete(sect)
  end for
  myreg.Flush()
End Function

Function SupportsAdvancedFeatures() as Boolean
  model = GetSession().deviceInfo.GetModel()
  return NOT model = "2710X" AND NOT model = "2720X" AND NOT model = "3100X" AND NOT model = "3050X" AND NOT model = "3000X"
end Function

Function DeParenString(stringToUpdate as string) as string
  position = Instr(1, stringToUpdate, "(")
  if position <> 0
    stringToUpdate = Left(stringToUpdate, position - 1)
  end if
  return stringToUpdate
End Function

Function StringRemoveHTMLTags(baseStr as String) as String
    r = CreateObject("roRegex", "<[^<]+?>", "i")
    return r.replaceAll(baseStr, "")
end function