[The Bat Player for Roku](http://thebatplayer.fm)
======================
A [BrightScript](http://sdkdocs.roku.com/display/sdkdoc/BrightScript+Language+Reference) application for listening to internet radio on your Roku media player.

###**Features**
1. Uses data from The Bat Server to display artist, track and album information and images.
2. Can take advantage of your Philips Hue connected lighting system to surround yourself in the colors that are on the screen.
3. Uses a web-based configuration page to configure the application instead of the remote and on-screen keyboards.
4. Can Scrobble to two different Last.FM accounts to keep your listening history up to date.
6. Uses a server-side component for image processing and metadata caching.

###**Dependencies**
1. Utilizes [RokuLib](https://github.com/dphang/roku-lib).
2. Analytics are enabled via Segment.IO and the [SegmentIO-Brightscript](https://github.com/gabek/SegmentIO-Brightscript) library.
3. The actual metadata work is done by [The Bat Server](https://github.com/gabek/TheBatPlayerServer).  A server-side application that does the heavy lifting.
4. The [web configuration](https://github.com/gabek/TheBatPlayerRoku/tree/master/html) portion of The Bat Player (http://roku:9999) uses a bunch of Javascript, css, and even PHP that live elsewhere that is used to assist users in adding stations.

###**Running**
1. Copy Config-example.brs to Config.brs.  Uncomment the file and add your respective keys.
2. Follow the deployment directions [On the Roku developer site](http://sdkdocs.roku.com/display/sdkdoc/Developer+Guide#DeveloperGuide-70LoadingandRunningyourApplicationWalkthrough).

###**Want to help?**
1. File a GitHub issue.
2. Create a pull request for a feature or bug fix.
3. Teach me something about Brightscript development I don't know.  This is my first Roku app.

[![Video](http://f.cl.ly/items/1O461y2v2N2D1k151Q0S/TheBatPlayerDemoGif.gif)](https://vimeo.com/112659447)
