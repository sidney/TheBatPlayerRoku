Function AlbumImage(filePath as String, x as Integer, y as Integer, enableFade = true as Boolean, maxAlpha = 225 as Integer, overlayColor = 0 as Integer) as Object

	this = {
		bitmap: invalid
		image: invalid
		alpha: &hFFFFFF00


		x: ResolutionX(x)
		y: ResolutionY(y)

		width: ResolutionY(210)
		height: ResolutionY(210)

		EnableFade: enableFade
		FadeIn: albumImage_FadeIn
		FadeOut: albumImage_FadeOut
		MaxFade: maxAlpha
		MinFade: 0

		isFadingIn: true
		isFadingOut: false
		fadeAmount: GetConfig().ImageFadeDuration
		overlayColor: overlayColor

		draw: albumImage_draw
	}

	this.bitmap = CreateObject("roBitmap", filePath)
	this.image = RlGetScaledImage(this.bitmap, this.width, this.height, 1)
	this.bitmap = invalid

	' Add the subtle overlay color
	if this.overlayColor <> 0 AND this.image <> invalid
		this.image.SetAlphaEnable(true)
		this.image.DrawRect(0, 0, this.image.GetWidth(), this.image.GetHeight(), this.overlayColor + 17)
		this.image.finish()
		this.image.SetAlphaEnable(false)
	end if

	'Disable fading for old devices
	if NOT SupportsAdvancedFeatures()
		this.alpha = this.alpha + this.MaxFade
		this.enableFade = false
	end if

	return this
End Function

Function albumImage_FadeIn()
	if SupportsAdvancedFeatures()
		m.isFadingIn = true
		m.isFadingOut = false
	end if
End Function

Function albumImage_FadeOut()
	if SupportsAdvancedFeatures()
		m.isFadingOut = true
		m.isFadingIn = false
	else
		m.alpha = &hFFFFFF00
		m.bitmap = invalid
	end if
End Function

Function albumImage_draw(screen as Object)
	if m.image <> invalid
		if m.enableFade
			if m.isFadingIn = true
				m.alpha = RlMin(&hFFFFFF00 + m.MaxFade, m.alpha + m.fadeAmount)
				if m.alpha = &hFFFFFF00 + m.MaxFade
					m.isFadingIn = false
				end if
			else if m.isFadingOut = true
				m.alpha = RlMax(&hFFFFFF00 + m.MinFade, m.alpha - m.fadeAmount)
				if m.alpha = &hFFFFFF00
					m.isFadingOut = false
					m.image = invalid
				end if
			end if
		else
			m.alpha = &hFFFFFF00 + m.MaxFade
		end if

		screen.DrawObject(m.x, m.y, m.image, m.alpha)

	end if
End Function
