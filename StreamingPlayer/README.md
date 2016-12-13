# StreamingPlayer Fuse Component

This component implements HTTP audio streaming for iOS and Android in Fuse. It exposes a JavaScript API called `PlaylistPlayer` which is reachable by `require('PlaylistPlayer')`.

## Native Features

- Play http streams
- Lock screen controls
    - Normal lock screen controls on iOS
    - MediaStyle notification for Android
    - Displays media metadata
        - Track title
        - Artist
        - Artwork
        - Duration
        - Progress
- Allows you to supply a full playlist of tracks in order to support lock screen controls.

## Limitations

- Only supports Android API level >= 21. Earlier API levels used a different system for lock screen media controls, which have not been wrapped yet.
- A few notification related callbacks have not yet been wrapped (like the clicked and removed actions).
