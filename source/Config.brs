Function GetConfig() as Object
	this = {
		type: "Config"

		SegmentApiKey: "v5tyminpyy"

		LastFMKey: "b6153d6e1039f86e308a79531f7c4b6f"
		LastFMSecret: "6ee44c8b24093c67dbe7f66aa82827e9"

		Batserver: "http://batserver.thebatplayer.fm/"
		MetadataFetchTimer: 8

		ImageDownloadTimeout: 5
	}

	return this
End Function
