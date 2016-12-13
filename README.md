# FuseCloud

FuseCloud is a cross-platform music player that interacts with the SoundCloud<sup>®</sup> API, made with [Fuse](https://www.fusetools.com).
It allows you to log in with your SoundCloud<sup>®</sup> user account and listen to your favorite tracks as well as discover new music through a news feed and conventional search.

This app was made to serve as a reference app for people getting started with cross-platform app development using Fuse and will also serve as the source for tutorials and guides related to app development in Fuse. It is made using the best practices of the platforms and shows of advanced use-cases like foreign code, custom JavaScript native modules, the Storage and InterApp modules and much more.

The app can be downloaded for both Android and iOS throug the [AppStore](https://itunes.apple.com/us/app/fusecloud/id1173516856?mt=8) and [Google Play Store](https://play.google.com/store/apps/details?id=com.fuse.fusecloud&hl=en).

We've written about the motivation behind this project in [this medium article](https://medium.com/@fusetools/i-made-a-cross-platform-soundcloud-player-with-fuse-9fb1e62b7db1#.lhu76dfj6).

## Setup

Register your app at https://soundcloud.com/you/apps. Assign a custom redirect uri to let SoundCloud<sup>®</sup> know how to route back to the app after the user has logged in. We chose fuse-soundcloud://fuse for our app, but you'll need to come up with a new one.

Add the uri scheme definition to the FuseCloud/FuseCloud.unoproj file (swap fuse-soundcloud with your scheme):

	"Mobile":{
		"UriScheme": "fuse-soundcloud",
		"Orientations": "Portrait"
	},

Copy the client id and client secret to SoundCloud/SoundCloudConfig.js

Start Fuse preview:
- iOS - `fuse preview -tios`
- Android - `fuse preview -tandroid`

* Note: Local preview works, but with a limited feature set:
	  - No audio stream
	  - No login

## Disclaimer

FuseCloud is an unofficial SoundCloud music player, and is not in any way endorsed by SoundCloud<sup>®</sup>. It simply uses the SoundCloud API.

## Features

- Authentication with SoundCloud<sup>®</sup> using OAuth 2.0
    - Using the InterApp package to launch url in external browser and repond to uri
    - Automatically refresh invalid tokens
- Fetching from REST API
- News feed, track search, favorites

- Like/unlike track
- Track artwork
- Display comments for track
- Post comment
- User profile stats

- Swipe left/right to go to previous/next track
- Pull to refresh
- Infinte scrolling lists
- Swipe to reveal list item actions (unlike in favorites view)
- Persistent UI state using the Storage API (welcome information only shows first time the app is started)®

- HTTP Audio StreamingPlayer for iOS and Android
    - Streaming music from SoundCloud<sup>®</sup>
	- Custom seek bar
    - Background audio
    - Lock screen controls on iOS and Android
        - iOS:
            - next, previous, play/pause, seek from lockscreen
            - lockscreen artwork
        - android media style notification:
            - next, previous, play/pause
            - displays artwork in notification and background
    - Playlists
    - Auto play next on song completed
	
## Note on the authentication flow on iOS

Apple considers opening an external browser as a part of the login flow to be poor UX design and suggests using the `SFSafariViewController` component instead.
We have therefore made a small wrapper around that component to allow showing it full screen inside the app.
