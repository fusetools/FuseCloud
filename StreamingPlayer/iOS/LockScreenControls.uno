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
	[ForeignInclude(Language.ObjC, "AudioToolbox/AudioToolbox.h")]
	[Require("Xcode.Framework", "MediaPlayer")]
	[Require("Xcode.Plist.Element", "<key>UIBackgroundModes</key><array><string>audio</string></array>")]
	extern(iOS) class LockScreenMediaControlsiOSImpl
	{

		IStreamingPlayer _player;
		
		public LockScreenMediaControlsiOSImpl(IStreamingPlayer iosPlayer)
		{
			debug_log("Registering handlers");
			RegisterHandlers(Next,Previous,Play,Pause,Seek);
			_player = iosPlayer;

			_player.HasNextChanged += OnHasNextChanged;
			_player.HasPreviousChanged += OnHasPreviousChanged;
		}

		void OnHasPreviousChanged(bool has)
		{
			if (has)
				ShowPreviousButton();
			else
				HidePreviousButton();
		}

		
		void OnHasNextChanged(bool has)
		{
			if (has)
				ShowNextButton();
			else
				HideNextButton();
		}

		void Next()
		{
			_player.Next();
		}
		void Previous()
		{
			_player.Previous();
		}

		
		void Play()
		{
			_player.Resume();
		}

		void Pause()
		{
			_player.Pause();
		}

		void Seek(double posInSec)
		{
			debug_log("seek from lock screen");
			var duration = _player.Duration;
			if (duration == 0.0)
				return;
			var progress = posInSec / duration;
			_player.Seek(progress);
		}

		[Foreign(Language.ObjC)]
		void HidePreviousButton()
		@{
			MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
			commandCenter.previousTrackCommand.enabled = false;
		@}

		[Foreign(Language.ObjC)]
		void ShowPreviousButton()
		@{
			MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
			commandCenter.previousTrackCommand.enabled = true;
		@}

		[Foreign(Language.ObjC)]
		void HideNextButton()
		@{
			MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
			commandCenter.nextTrackCommand.enabled = false;
		@}

		[Foreign(Language.ObjC)]
		void ShowNextButton()
		@{
			MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
			commandCenter.nextTrackCommand.enabled = true;			
		@}

		[Foreign(Language.ObjC)]
		void RegisterHandlers(Action next, Action previous, Action play, Action pause, Action<double> seek)
		@{
			AVAudioSession *audioSession = [AVAudioSession sharedInstance];

			NSError *setCategoryError = nil;
			BOOL success = [audioSession setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
			if (!success) { NSLog(@"Error setting category"); }

			NSError *activationError = nil;
			success = [audioSession setActive:YES error:&activationError];
			if (!success) { NSLog(@"Error setting active audio session"); }


			MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
        	[commandCenter.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        	    NSLog(@"Play button pressed");
				play();
        	    return MPRemoteCommandHandlerStatusSuccess;
        	}];
		    [commandCenter.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        	    NSLog(@"Pause button pressed");
				pause();
        	    return MPRemoteCommandHandlerStatusSuccess;
        	}];		
        	[commandCenter.nextTrackCommand addTargetWithHandler:^(MPRemoteCommandEvent *event) {
        		// Begin playing the current track.
        		NSLog(@"Remote control: next track command");
				next();
        	    return MPRemoteCommandHandlerStatusSuccess;
        	}];
			[commandCenter.previousTrackCommand addTargetWithHandler:^(MPRemoteCommandEvent *event) {
        		// Begin playing the current track.
        		NSLog(@"Remote control: previous track command");
				previous();
        	    return MPRemoteCommandHandlerStatusSuccess;
        	}];

			//NSLog(@"current API iOS Version: %f", NSFoundationVersionNumber);
			//NSLog(@"required API iOS Version: %f", NSFoundationVersionNumber_iOS_9_0);
			if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_0) {	
				[commandCenter.changePlaybackPositionCommand addTargetWithHandler:^(MPRemoteCommandEvent *event) {
						MPChangePlaybackPositionCommandEvent* seekEvent = (MPChangePlaybackPositionCommandEvent*)event;
						NSTimeInterval posTime = seekEvent.positionTime;
						//NSLog(@"Remote control: seek to pos command: %f", posTime);
						seek(posTime);
						return MPRemoteCommandHandlerStatusSuccess;
					}];
			}
		@}

	}

}
