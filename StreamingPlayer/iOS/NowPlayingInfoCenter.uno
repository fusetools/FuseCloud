using Uno;
using Uno.UX;
using Uno.Threading;
using Fuse.Scripting;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace StreamingPlayer
{

	[ForeignInclude(Language.ObjC, "AVFoundation/AVFoundation.h")]

	[ForeignInclude(Language.ObjC, "MediaPlayer/MediaPlayer.h")]
	[Require("Xcode.Framework", "MediaPlayer")]

	[Require("Xcode.Framework", "CoreImage")]
	[ForeignInclude(Language.ObjC, "CoreImage/CoreImage.h")]
	extern(iOS) static class NowPlayingInfoCenter
	{


		public static void SetProgress(double progress)
		{
			SetProgressImpl(progress);
		}

		[Foreign(Language.ObjC)]
		static void SetProgressImpl(double progress)
		@{		
			NSMutableDictionary *playInfo = [NSMutableDictionary dictionaryWithDictionary:[MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo];

			[playInfo setObject: [NSNumber numberWithDouble:progress] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
			[MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = playInfo;
		@}

		public static void SetTrackInfo(Track track)
		{
			SetNowPlayingInfoCenterInfo(track.Name, track.Artist, NowPlayingInfoCenter.CreateArtworkFromUrl(track.ArtworkUrl), track.Duration);
		}
		
		[Foreign(Language.ObjC)]
		static void SetNowPlayingInfoCenterInfo(string title, string artistName, ObjC.Object artwork, double duration)
		@{
			MPMediaItemArtwork *aw = (MPMediaItemArtwork*)artwork;

			NSMutableDictionary *playInfo = [NSMutableDictionary dictionaryWithDictionary:[MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo];

            [playInfo setObject: title forKey:MPMediaItemPropertyTitle];
			[playInfo setObject: artistName forKey:MPMediaItemPropertyArtist];
			if (aw != nil) {
				[playInfo setObject: aw forKey:MPMediaItemPropertyArtwork];
			}
			[playInfo setObject: [NSNumber numberWithDouble:duration] forKey:MPMediaItemPropertyPlaybackDuration];
			[playInfo setObject: [NSNumber numberWithDouble:0.0] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
			[MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = playInfo;
		@}

		static ObjC.Object CreateArtworkFromUrl(string url)
		{
			return MediaArtworkFromUrl(url);
		}

		[Foreign(Language.ObjC)]
		static ObjC.Object MediaArtworkFromUrl(string url)
		@{
			UIImage *uiImage = [UIImage imageWithData:[NSData dataWithContentsOfURL: [[NSURL alloc] initWithString: url]]];
			if (uiImage != nil) {
				return [[MPMediaItemArtwork alloc] initWithImage:uiImage];
				
			}
			return nil;
		@}
	}
}
