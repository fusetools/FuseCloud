using Uno;
using Uno.UX;
using Uno.Threading;
using Fuse.Scripting;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace StreamingPlayer
{

	internal enum iOSPlayerState
	{
		Unknown, Initialized, Error
	}

	[ForeignInclude(Language.ObjC, "AVFoundation/AVFoundation.h")]

	[ForeignInclude(Language.ObjC, "MediaPlayer/MediaPlayer.h")]
	[Require("Xcode.Framework", "MediaPlayer")]

	[Require("Xcode.Framework", "CoreImage")]
	[ForeignInclude(Language.ObjC, "CoreImage/CoreImage.h")]
	extern(iOS) class StreamingPlayeriOSImpl : IStreamingPlayer
	{

		static readonly string _statusName = "status";
		static readonly string _isPlaybackLikelyToKeepUp = "playbackLikelyToKeepUp";

		static ObjC.Object _player;
		ObjC.Object CurrentPlayerItem
		{
			get { return GetCurrentPlayerItem(_player); }
		}
		
		List<Track> _tracks = new List<Track>();
		
		public event StatusChangedHandler StatusChanged;
		public event Action CurrentTrackChanged;
		public event Action<bool> HasNextChanged;
		public event Action<bool> HasPreviousChanged;

		iOSPlayerState _internalState = iOSPlayerState.Unknown;

		static StreamingPlayeriOSImpl _current;

		void OnIsLikelyToKeepUpChanged()
		{
			debug_log("Is likely to keep ups :S");
			if (Status == PlayerStatus.Paused)
				return;
			var isLikelyToKeepUp = IsLikelyToKeepUp;
			if (isLikelyToKeepUp) {
				var newState = GetStatus(_player);
				var rate = GetRate(_player);
				if (rate < 1.0) {
					Resume();
				}
				Status = PlayerStatus.Playing;
			}
		}

		[Foreign(Language.ObjC)]
		float GetRate(ObjC.Object player)
		@{
			AVPlayer* p = (AVPlayer*)player;
			return [p rate];
		@}
		
		public void Play(Track track)
		{
			debug_log("Play UNO called");
			Status = PlayerStatus.Loading;
			if (_player == null){
				_player = Create(track.Url);
				ObserverProxy.AddObserver(CurrentPlayerItem, _isPlaybackLikelyToKeepUp, 0, OnIsLikelyToKeepUpChanged);
				ObserverProxy.AddObserver(CurrentPlayerItem, _statusName, 0, OnInternalStateChanged);
			}
			else
			{
				_internalState = iOSPlayerState.Unknown;
				ObserverProxy.RemoveObserver(CurrentPlayerItem, _statusName);
				ObserverProxy.RemoveObserver(CurrentPlayerItem, _isPlaybackLikelyToKeepUp);

				AssignNewPlayerItemWithUrl(_player, track.Url);
				
				ObserverProxy.AddObserver(CurrentPlayerItem, _isPlaybackLikelyToKeepUp, 0, OnIsLikelyToKeepUpChanged);
				ObserverProxy.AddObserver(CurrentPlayerItem, _statusName, 0, OnInternalStateChanged);
			}

			NowPlayingInfoCenter.SetTrackInfo(track);

			CurrentTrack = track;
			if (_internalState == iOSPlayerState.Initialized) {
				PlayImpl(_player);
			}
		}

		void PlayerItemDidReachEnd()
		{
			debug_log("We did reach the end of our track");
			Next();
		}

		[Foreign(Language.ObjC)]
		void ObserveAVPlayerItemDidPlayToEndTimeNotification(Action callback, ObjC.Object playerItem)
		@{
			AVPlayerItem* pi = (AVPlayerItem*)playerItem;
			[[NSNotificationCenter defaultCenter]
			 	addObserverForName:(NSNotificationName)AVPlayerItemDidPlayToEndTimeNotification
			 	object:pi
			 	queue:nil
			 	usingBlock: ^void(NSNotification *note) {
					NSLog(@"Note %a", note.name);
					callback();
			 	}
			];	 
		@}

		public void Resume()
		{
			debug_log("Resume UNO called");
			if (_player != null)
			{
				PlayImpl(_player);
				Status = PlayerStatus.Playing;
			}
		}

		public void Pause()
		{
			if (_player != null)
			{
				PauseImpl(_player);
				Status = PlayerStatus.Paused;
			}
		}

		public void Stop()
		{
			if (_player != null)
			{
				SetPosition(_player, 0.0);
				ObserverProxy.RemoveObserver(CurrentPlayerItem, _statusName);
				ObserverProxy.RemoveObserver(CurrentPlayerItem, _isPlaybackLikelyToKeepUp);
				StopAndRelease(_player);
				Status = PlayerStatus.Stopped;
				_internalState = iOSPlayerState.Unknown;
				_player = null;
			}
		}

		public void Seek(double toProgress)
		{
			if (Status == PlayerStatus.Loading)
				return;
			var time = Duration * toProgress;
			SetPosition(_player, time);
			NowPlayingInfoCenter.SetProgress(toProgress * Duration);
		}

		public double Duration
		{
			get { return (_player != null) ? GetDuration(_player) : 0.0; }
		}

		public double Progress
		{
			get { return (_player != null) ? GetPosition(_player) : 0.0; }
		}

		PlayerStatus _status = PlayerStatus.Stopped;
		public PlayerStatus Status
		{
			get
			{
				if (_player != null)
				{
					switch (_internalState)
					{
						case iOSPlayerState.Unknown:
							return PlayerStatus.Stopped;
						case iOSPlayerState.Initialized:
							return _status;
						default:
							return PlayerStatus.Error;
					}
				}
				return PlayerStatus.Error;
			}
			private set
			{
				_status = value;
				OnStatusChanged();
			}
		}

		string InternalStateToString(int s)
		{
			switch (s)
			{
				case 0: return "Unknown";
				case 1: return "Initialized";
				default: return "Error";
			}
		}
		
		void OnInternalStateChanged()
		{
			var newState = GetStatus(_player);
			var lastState = _internalState;
			switch (newState)
			{
				case 0: _internalState = iOSPlayerState.Unknown; break;
				case 1: _internalState = iOSPlayerState.Initialized; break;
				default: _internalState = iOSPlayerState.Error; break;
			}
			if (_internalState == iOSPlayerState.Initialized && _internalState != lastState)
				PlayImpl(_player);
		}

		void OnStatusChanged()
		{
			if (_internalState == iOSPlayerState.Initialized && Status == PlayerStatus.Stopped)
				PlayImpl(_player);

			if (StatusChanged != null)
				StatusChanged(Status);
		}

		bool IsLikelyToKeepUp
		{
			get { return GetIsLikelyToKeepUp(_player); }
		}

		[Foreign(Language.ObjC)]
		bool GetIsLikelyToKeepUp(ObjC.Object player)
		@{
			AVPlayer* p = (AVPlayer*)player;
			return [[p currentItem] isPlaybackLikelyToKeepUp];
		@}
		
		[Foreign(Language.ObjC)]
		int GetStatus(ObjC.Object player)
		@{
			AVPlayer* p = (AVPlayer*)player;
			return [[p currentItem] status];
		@}

		[Foreign(Language.ObjC)]
		void StopAndRelease(ObjC.Object player)
		@{
			AVPlayer* p = (AVPlayer*)player;
			[p pause];
		@}

		[Foreign(Language.ObjC)]
		static ObjC.Object Create(string url)
		@{
			return 	[[AVPlayer alloc] initWithURL:[[NSURL alloc] initWithString: url]];
		@}

		[Foreign(Language.ObjC)]
		void AssignNewPlayerItemWithUrl(ObjC.Object player, string url)
		@{
			AVPlayer* p = (AVPlayer*)player;
			p.rate = 0.0f;
			AVPlayerItem* item = [[AVPlayerItem alloc] initWithURL: [[NSURL alloc] initWithString: url]];
			[p replaceCurrentItemWithPlayerItem: item];
		@}

		[Foreign(Language.ObjC)]
		void PlayImpl(ObjC.Object player)
		@{
			AVPlayer* p = (AVPlayer*)player;
			[p play];
		@}

		[Foreign(Language.ObjC)]
		void PauseImpl(ObjC.Object player)
		@{
			AVPlayer* p = (AVPlayer*)player;
			[p pause];
		@}

		[Foreign(Language.ObjC)]
		double GetDuration(ObjC.Object player)
		@{
			AVPlayer* p = (AVPlayer*)player;
			return CMTimeGetSeconds([[[p currentItem] asset] duration]);
		@}

		[Foreign(Language.ObjC)]
		double GetPosition(ObjC.Object player)
		@{
			AVPlayer* p = (AVPlayer*)player;
			return CMTimeGetSeconds([[p currentItem] currentTime]);
		@}


		[Foreign(Language.ObjC)]
		void SetPosition(ObjC.Object player, double position)
		@{
			AVPlayer* p = (AVPlayer*)player;
			[p seekToTime: CMTimeMake(position * 1000, 1000)];
		@}

		[Foreign(Language.ObjC)]
		ObjC.Object GetCurrentPlayerItem(ObjC.Object player)
		@{
			AVPlayer* p = (AVPlayer*)player;
			return p.currentItem;
		@}

		static bool DidAddAVPlayerItemDidPlayToEndTimeNotification = false;
		public StreamingPlayeriOSImpl()
		{
			new LockScreenMediaControlsiOSImpl(this);
			if (!DidAddAVPlayerItemDidPlayToEndTimeNotification)
			{
				debug_log("REGISTERING OBS");
				ObserveAVPlayerItemDidPlayToEndTimeNotification(PlayerItemDidReachEnd, CurrentPlayerItem);
				DidAddAVPlayerItemDidPlayToEndTimeNotification = true;
			}
		}

		Track _currentTrack;
		public Track CurrentTrack
		{
			get
			{
				return _currentTrack;
			}
			set
			{
				_currentTrack = value;
				OnCurrentTrackChanged();
			}
		}

		public bool HasNext
		{
			get
			{
				if (CurrentTrack == null) {
					return false;
				}
				var index = _tracks.IndexOf(CurrentTrack);
				var ret = index > -1 && index < _tracks.Count - 1;
				return ret;
			}
		}

		public bool HasPrevious
		{
			get
			{
				if (CurrentTrack == null)
					return false;
				var ret = _tracks.IndexOf(CurrentTrack) > 0;
				return ret;
			}
		}

		void OnCurrentTrackChanged()
		{
			if (CurrentTrackChanged != null) {
				CurrentTrackChanged();
			}
			OnHasNextOrHasPreviousChanged();
		}

		public void AddTrack(Track track)
		{
			_tracks.Add(track);
			OnHasNextOrHasPreviousChanged();
		}

		public void SetPlaylist(Track[] tracks)
		{
			_tracks.Clear();
			if (tracks == null)
				return;
			foreach (var t in tracks)
				_tracks.Add(t);
			OnHasNextOrHasPreviousChanged();
		}

		public int Next()
		{
			debug_log("UNO: trying next ");
			if (HasNext)
			{
				debug_log("UNO: did do next");
				var newTrack = _tracks[_tracks.IndexOf(CurrentTrack) + 1];
				Play(newTrack);
				CurrentTrack = newTrack;
				return newTrack.Id;
			}
			return -1;
		}

		public int Previous()
		{
			if (HasPrevious)
			{
				var newTrack = _tracks[_tracks.IndexOf(CurrentTrack) - 1];
				Play(newTrack);
				CurrentTrack = newTrack;
				return newTrack.Id;
			}
			return -1;
		}

		void OnHasNextOrHasPreviousChanged()
		{
			if (HasNextChanged != null)
				HasNextChanged(HasNext);
			if (HasPreviousChanged != null)
				HasPreviousChanged(HasPrevious);
		}
	}
}
