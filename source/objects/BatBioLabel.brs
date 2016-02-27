Function BatBioLabel(text as string, song as object, enableFade = true as Boolean) as Object
	this = {
		text: text
		labelObject: invalid
		dropShadowObject: invalid
		image: invalid

		alpha: &hFFFFFF00
		isFadingIn: true
		isFadingOut: false
		fadeAmount: GetConfig().ImageFadeDuration
		EnableFade: enableFade
		FadeIn: bioLabel_FadeIn
		FadeOut: bioLabel_FadeOut
		MaxFade: 255
		MinFade: 0

		Font: GetMediumFont()

		x: ResolutionX(90)
		y: ResolutionY(510)
		width: ResolutionX(1090)
		height: ResolutionY(200)

		draw: bioLabel_draw

	}

	this.labelObject = RlTextArea(this.text, this.Font, GetRegularColorForSong(song), 0, 0, this.width, this.height, 8, 1.14, "left", true, true)

	dropShadowColor = GetDropShadowColorForSong(song)
	if dropShadowColor <> 0
		this.dropShadowObject = RlTextArea(this.text, this.Font, dropShadowColor, 1.0, 2.0, this.width, this.height, 8, 1.14, "left", true, true)
	end if

	' Create the bitmap
	this.image = CreateObject("roBitmap", {width:this.width, height: this.height, alphaenable: true})
	'this.dropShadowObject.Draw(this.image)
	this.labelObject.Draw(this.image)
	this.image.finish()
	this.image.SetAlphaEnable(false)

	return this
End Function

Function bioLabel_FadeIn()
	if SupportsAdvancedFeatures()
		m.isFadingIn = true
		m.isFadingOut = false
	end if
End Function

Function bioLabel_FadeOut()
	if SupportsAdvancedFeatures()
		m.isFadingOut = true
		m.isFadingIn = false
	else
		m.alpha = &hFFFFFF00
		m.bitmap = invalid
	end if
End Function

Function bioLabel_draw(screen as Object)

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
			'Fade disabled
			m.alpha = &hFFFFFF00 + m.MaxFade
		end if
	end if

	screen.DrawObject(m.x, m.y, m.image, m.alpha)

End Function
