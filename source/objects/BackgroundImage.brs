Function BackgroundImage(filePath as String, overlayColor = 0 as Integer, grungeColor = 255 as Integer) as Object

	this = {
		bitmap: invalid
		image: invalid

		size: invalid
		alpha: &hFFFFFF00

		overlayColor: overlayColor
		grungeColor: grungeColor

		FadeIn: backgroundImage_FadeIn
		FadeOut: backgroundImage_FadeOut
		MaxFade: 255
		MinFade: 0

		isFadingIn: true
		isFadingOut: false
		fadeAmount: GetConfig().ImageFadeDuration

		valid: false

		draw: backgroundImage_draw
	}

	this.size = GetSession().deviceInfo.GetDisplaySize()
	bitmap = CreateObject("roBitmap", filePath)
	BackgroundGrunge = RlGetScaledImage(CreateObject("roBitmap", "pkg:/images/background-grunge.png"), this.size.w, this.size.h, 1)
	Bat = CreateObject("roBitmap", "pkg:/images/bat.png")

	if bitmap = invalid then
		print "*** Background image is INVALID"
		return invalid
	end if

	this.image = RlGetScaledImage(bitmap, this.size.w, this.size.h, 1)
	if this.image = invalid
		return invalid
	end if

	this.valid = true

	'Disable fading for old devices
	if NOT SupportsAdvancedFeatures()
		this.alpha = this.alpha + this.MaxFade
	end if

	GradientTop = CreateObject("roBitmap", "pkg:/images/background-gradient-overlay-top.png")
  GradientBottom = CreateObject("roBitmap", "pkg:/images/background-gradient-overlay-bottom.png")

	if this.image <> invalid
		this.image.SetAlphaEnable(true)

		'Bats
		for i = 0 to 5
			rotation = Rnd(40)
			if Rnd(1) > 0
				rotation = rotation * -1
			end if
			x = Rnd(this.size.w)
			y = Rnd(this.size.h)
			alpha = RlMin(Rnd(40), 20)
			this.image.DrawRotatedObject(x, y, rotation, Bat, &hFFFFFF00 + alpha)
		end for

		this.image.DrawObject(0, 0, BackgroundGrunge, &hAAAAAA00 + 220) 'Grunge overlay
		if this.OverlayColor <> invalid
			this.image.DrawRect(0, 0, this.size.w, this.size.h, this.OverlayColor) 'Color overlay
		end if

		this.image.DrawObject(0, 0, GradientTop, &hFFFFFF + 235) 'Top Gradient
		this.image.DrawObject(0, this.size.h - 365, GradientBottom, &hFFFFFF + 255) 'Bottom Gradient

		this.image.DrawRect(0, 0, this.size.w, this.size.h, &h00000000 + 205) 'Black overlay

		this.image.SetAlphaEnable(false)
		this.image.finish()
	end if

	'Reclaim memory
	this.BackgroundGrunge = invalid
	this.bitmap = invalid
	GradientTop = invalid
	GradientBottom = invalid
	return this
End Function

Function backgroundImage_FadeIn()
	if SupportsAdvancedFeatures()
		m.isFadingIn = true
		m.isFadingOut = false
	end if
End Function

Function backgroundImage_FadeOut()
	if SupportsAdvancedFeatures()
		m.isFadingOut = true
		m.isFadingIn = false
	else
		m.bitmap = invalid
	end if
End Function

Function backgroundImage_draw(screen as Object)
	if m.image <> invalid
		if m.isFadingIn = true
			m.alpha = RlMin(&hFFFFFF00 + m.MaxFade, m.alpha + m.fadeAmount)
			if m.alpha = &hFFFFFF00 + m.MaxFade
				m.isFadingIn = false
			end if
		else if m.isFadingOut = true
			m.alpha = RlMax(&hFFFFFF00 + m.MinFade, m.alpha - m.fadeAmount)
			if m.alpha = &hFFFFFF00
				m.isFadingOut = false
				m.bitmap = invalid
				m = invalid
				return true
			end if
		end if
		screen.DrawObject(0, 0, m.image, m.alpha)
	end if
End Function
