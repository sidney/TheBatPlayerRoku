Function FileExists(Filename as String) as Boolean
    FileSystem = CreateObject("roFileSystem")
    return FileSystem.Exists("tmp:/" + Filename)
End Function

Function DeleteTmpFile(Filename as String)
    FileSystem = CreateObject("roFileSystem")
    FileSystem.Delete(Filename)
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

Function GetIPAddress() as String
  IPs = GetSession().deviceInfo.getIpAddrs()
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
  return true
  'model = GetSession().deviceInfo.GetModel()
  'return NOT model = "2710X" AND NOT model = "2720X" AND NOT model = "3100X" AND NOT model = "3050X" AND NOT model = "3000X"
end Function

Function DeParenString(stringToUpdate as string) as string
  position = Instr(1, stringToUpdate, "(")
  if position <> 0
    stringToUpdate = Left(stringToUpdate, position - 1)
  end if
  return stringToUpdate
End Function

Function StringRemoveHTMLTags(baseStr as String) as String
  r = CreateObject("roRegEx", "<.*?>", "")
  return r.replaceAll(baseStr, "")
end function

Function AssocArrayCount(aa as object) as Integer
    'Returns the number of entries in an roAssociativeArray
    i = 0
    for each k in aa
        i = i + 1
    end for
    return i
End Function

Function SizeOfImageAtPath(path as String) as Object
  metadata = CreateObject("roImageMetadata")
  metadata.SetUrl(path)

  if metadata <> invalid
    size = CreateObject("roAssociativeArray")
    size.width = metadata.GetMetadata().width
    size.height = metadata.GetMetadata().height

    return size
  else
    return invalid
  end if
End Function


function HtmlEntityDecode(inStr)
  result = inStr

  if result <> invalid

    rx = CreateObject("roRegEx", "&#39;", "")
    result = rx.ReplaceAll(result, "'")

    rx = CreateObject("roRegEx", "&amp;", "")
    result = rx.ReplaceAll(result, "&")

    rx = CreateObject("roRegEx", "&(quot|rsquo|lsquo);", "")
    result = rx.ReplaceAll(result, Chr(34))

    rx = CreateObject("roRegEx", "&\w+;", "")
    result = rx.ReplaceAll(result, Chr(34))
  end if

  return result
end function

Function SanitizeStreamUrl(url)
  if url.Right(1) <> "/" AND url.Right(2) <> "/;"
    return url + "/"
  end if
  
  if url.Right(2) = "/;"
    return url
  end if

  if url.Right(1) <> "/"
    url = url + "/;"
    return url
  end if

  if url.Right(1) = "/"
    url = url + ";"
    return url
  end if

  return url
end function

Function GetTruncatedString(str as String) as String
  maxLength = 63
  if str.len() < maxLength
    return str
  end if

  return str.left(maxLength) + "..."
End function

Function CapitalizeString(str) as String  
  firstCharacter = str.left(1)
  capitalizedFirstCharacter = Ucase(firstCharacter)
  restOfString = str.mid(1)
  newString = capitalizedFirstCharacter + restOfString

  return newString
End Function