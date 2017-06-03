function getBlurredBackgroundImageURL(imageUrl) as String
    encodedURL = imageUrl.EncodeUri()
    backgroundURL = "https://zimage.global.ssl.fastly.net/?url=" + encodedURL + "&format=jpeg&quality=40&height=720&width=1080&mode=stretch&blur=30"
    
    return backgroundURL
end function
