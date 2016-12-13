using Uno;
using Uno.UX;
using Uno.Threading;
using Fuse.Scripting;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace StreamingPlayer
{
	[ForeignInclude(Language.Java,
					"android.media.MediaPlayer",
					"android.media.AudioManager",
					"java.lang.Exception")]
	[Require("AndroidManifest.ApplicationElement", "<service android:name=\"streamingPlayer.android.BackgroundAudioService\" />")]
	extern(Android) class StreamingPlayerAndroidImpl : IStreamingPlayer
	{
		Java.Object _player; //BackgroundAudioPlayer


		public event Action CurrentTrackChanged;
		public event Action<bool> HasNextChanged;
		public event Action<bool> HasPreviousChanged;

		PlayerStatus _status = PlayerStatus.Stopped;
		public PlayerStatus Status
		{
			get { return _status; }
			private set
			{
				var last = _status;
				_status = value;
				if (last != value)
					OnStatusChanged();
			}
		}

		public event StatusChangedHandler StatusChanged;

		void OnStatusChanged()
		{
			debug_log("Status changed (uno): " + Status);
			if (StatusChanged != null)
				StatusChanged(Status);
		}

		void HasPrevNextChanged()
		{
			if (HasNextChanged != null)
				HasNextChanged(HasNext);
			if (HasPreviousChanged != null)
				HasPreviousChanged(HasPrevious);
		}

		void OnCurrentTrackChanged()
		{
			debug_log("Current track changed");
			if (CurrentTrackChanged != null)
				CurrentTrackChanged();
		}

		static StreamingPlayerAndroidImpl _current;
		public StreamingPlayerAndroidImpl()
		{
			debug_log("Created streamingplayerandroidimpl");
			InternalStatusChanged(0);
			if (_current != null){
				_current.Stop();
			}
			_current = this;
		}

		void InternalStatusChanged(int i)
		{
			switch (i)
			{
				case 0:
				case 1:
					Status = PlayerStatus.Stopped;
					break;
				case 2:
				case 3:
					Status = PlayerStatus.Loading;
					break;
				case 4:
					Status = PlayerStatus.Playing;
					break;
				case 5:
					Status = PlayerStatus.Stopped;
					break;
				case 6:
					Status = PlayerStatus.Paused;
					break;
				case 7:
					Status = PlayerStatus.Stopped;
					break;
				case 8:
					Status = PlayerStatus.Error;
					break;
				case 9:
					Status = PlayerStatus.Stopped;
					break;
			}
		}

		[Foreign(Language.Java)]
		Java.Object ToJavaTrack(int id, string name, string artist, string url, string artworkUrl, double duration)
		@{
			return new streamingPlayer.android.Track(id,name,artist,url,artworkUrl,duration);
		@}

		public void Play(Track track)
		{
			if (_player == null)
			{
				_player = CreatePlayerImpl(InternalStatusChanged, HasPrevNextChanged, OnCurrentTrackChanged);
			}
			var javaTrack = ToJavaTrack(track.Id, track.Name, track.Artist, track.Url, track.ArtworkUrl, track.Duration);
			Status = PlayerStatus.Loading;
			PlayImpl(_player, javaTrack);
		}

		[Foreign(Language.Java)]
		void PlayImpl(Java.Object player, Java.Object track)
		@{
			streamingPlayer.android.Track t = (streamingPlayer.android.Track)track;
			((streamingPlayer.android.BackgroundAudioPlayer)player).Play(t);
		@}

		[Foreign(Language.Java)]
		Java.Object CreatePlayerImpl(Action<int> stateCallback,
									 Action hasPrevNextChanged,
									 Action currentTrackChanged)
		@{
			try
			{
				android.util.Log.d("StreamingPlayer", "CREATING PLAYER IN JAVA FOREIGN");
				streamingPlayer.android.BackgroundAudioPlayer backgroundPlayer =
					new streamingPlayer.android.BackgroundAudioPlayer(com.fuse.Activity.getRootActivity(),
																	  stateCallback,
																	  hasPrevNextChanged,
																	  currentTrackChanged);
				return backgroundPlayer;
			}
			catch (Exception e)
			{
				android.util.Log.d("StreamingPlayer", "We were not able to create a media player :S" + e.toString());
			}
			return null;
		@}

		public void Resume()
		{
			if (_player != null)
			{
				Status = PlayerStatus.Playing;
				ResumeImpl(_player);
			}
		}

		[Foreign(Language.Java)]
		void ResumeImpl(Java.Object player)
		@{
			((streamingPlayer.android.BackgroundAudioPlayer)player).Resume();
		@}

		public void Seek(double toProgress)
		{
			if (_player == null) return;
			var timeMS = (int)(Duration * toProgress * 1000);
			SeekImpl(_player, timeMS);
		}

		[Foreign(Language.Java)]
		void SeekImpl(Java.Object player, int timeMS)
		@{
			((streamingPlayer.android.BackgroundAudioPlayer)player).Seek(timeMS);
		@}

		public double Duration
		{
			get
			{
				if (_player == null)
					return 0;
				return GetDuration(_player) / 1000.0;
			}
		}

		[Foreign(Language.Java)]
		double GetDuration(Java.Object player)
		@{
			return ((streamingPlayer.android.BackgroundAudioPlayer)player).GetCurrentTrackDuration();
		@}

		public double Progress
		{
			get
			{
				if (_player == null)
					return 0;
				var ret = GetProgress(_player) / 1000.0;
				return ret;
			}
		}

		[Foreign(Language.Java)]
		double GetProgress(Java.Object player)
		@{
			return ((streamingPlayer.android.BackgroundAudioPlayer)player).GetCurrentPosition();
		@}

		public void Pause()
		{
			if (_player != null)
			{
				Status = PlayerStatus.Paused;
				PauseImpl(_player);
			}
		}

		[Foreign(Language.Java)]
		void PauseImpl(Java.Object player)
		@{
			((streamingPlayer.android.BackgroundAudioPlayer)player).Pause();
		@}

		public void Stop()
		{
			if (_player == null)
				return;
			Status = PlayerStatus.Paused;
			StopImpl(_player);
		}

		[Foreign(Language.Java)]
		void StopImpl(Java.Object player)
		@{
			((streamingPlayer.android.BackgroundAudioPlayer)player).Stop();
		@}


		//int id, string name, string url, string artworkUrl, double duration
		public void SetPlaylist(Track[] tracks)
		{
			int[] ids = new int[tracks.Length];
			string[] names = new string[tracks.Length];
			string[] artists = new string[tracks.Length];
			string[] urls = new string[tracks.Length];
			string[] artworkUrls = new string[tracks.Length];
			double[] durations = new double[tracks.Length];
												
			for (int i = 0; i < tracks.Length; i++) {
				var t = tracks[i];
				ids[i] = t.Id;
				names[i] = t.Name;
				artists[i] = t.Artist;
				urls[i] = t.Url;
				artworkUrls[i] = t.ArtworkUrl;
				durations[i] = t.Duration;
			}
			if (_player == null)
				_player = CreatePlayerImpl(InternalStatusChanged, HasPrevNextChanged, OnCurrentTrackChanged);
			debug_log("Android: set current playlist");
			SetPlaylistImpl(_player, ids, names, artists, urls, artworkUrls, durations);
		}

		[Foreign(Language.Java)]
		void SetPlaylistImpl(Java.Object player,
							 int[] ids,
							 string[] names,
							 string[] artists,
							 string[] urls,
							 string[] artworkUrls,
							 double[] durations)
		@{
			int[] i = ids.copyArray();
			String[] n = names.copyArray();
			String[] art = artists.copyArray();
			String[] u = urls.copyArray();
			String[] a = artworkUrls.copyArray();
			double[] d = durations.copyArray();
			streamingPlayer.android.Track[] tracks = new streamingPlayer.android.Track[i.length];
			for (int j = 0; j < i.length; j++) {
				streamingPlayer.android.Track t = new streamingPlayer.android.Track(i[j],n[j],art[j],u[j],a[j],d[j]);
				tracks[j] = t;
			}
			
			((streamingPlayer.android.BackgroundAudioPlayer)player).SetPlaylist(tracks);
		@}

		public int Next()
		{
			if (_player != null)
				return NextImpl(_player);
			return 0;
		}
		[Foreign(Language.Java)]
		int NextImpl(Java.Object player)
		@{
			return ((streamingPlayer.android.BackgroundAudioPlayer)player).Next();
		@}
		
		public int Previous()
		{
			if (_player != null)
				return PreviousImpl(_player);
			return 0;
		}
		[Foreign(Language.Java)]
		int PreviousImpl(Java.Object player)
		@{
			return ((streamingPlayer.android.BackgroundAudioPlayer)player).Previous();
		@}
		public void AddTrack(Track track)
		{
			if (_player != null)
				AddTrackImpl(_player, track);
		}
		[Foreign(Language.Java)]
		void AddTrackImpl(Java.Object player, object track)
		@{
			int id = @{Track:Of(track).Id:Get()};
			String name = @{Track:Of(track).Name:Get()};
			String artist = @{Track:Of(track).Artist:Get()};
			String url = @{Track:Of(track).Url:Get()};
			String artworkUrl = @{Track:Of(track).ArtworkUrl:Get()};
			double duration = @{Track:Of(track).Duration:Get()};
			streamingPlayer.android.Track jTrack = new streamingPlayer.android.Track(id,name,artist,url,artworkUrl,duration);
			((streamingPlayer.android.BackgroundAudioPlayer)player).AddTrack(jTrack);
		@}

		public Track CurrentTrack
		{
			get
			{
				if (_player != null){
					var currentTrackJava = GetCurrentTrackImpl(_player);
					if (currentTrackJava != null)
					{
						var id = TrackAndroidImpl.GetId(currentTrackJava);
						var name = TrackAndroidImpl.GetName(currentTrackJava);
						var artist = TrackAndroidImpl.GetArtist(currentTrackJava);
						var url = TrackAndroidImpl.GetUrl(currentTrackJava);
						var artworkUrl = TrackAndroidImpl.GetArtworkUrl(currentTrackJava);
						var duration = TrackAndroidImpl.GetDuration(currentTrackJava);
						var ret = new Track(id,name,artist,url,artworkUrl,duration);
						return ret;
					}
				}
				return null;
			}
		}
		
		[Foreign(Language.Java)]
		Java.Object GetCurrentTrackImpl(Java.Object player)
		@{
			return ((streamingPlayer.android.BackgroundAudioPlayer)player).GetCurrentTrack();
		@}
		
		public bool HasNext
		{
			get
			{
				if (_player != null)
					return GetHasNextImpl(_player);
				return false;
			}
		}
		
		[Foreign(Language.Java)]
		bool GetHasNextImpl(Java.Object player)
		@{
			return ((streamingPlayer.android.BackgroundAudioPlayer)player).HasNext();
		@}
		
		public bool HasPrevious
		{
			get
			{
				if (_player != null)
					return GetHasPreviousImpl(_player);
				return false;
			}
		}

		[Foreign(Language.Java)]
		bool GetHasPreviousImpl(Java.Object player)
		@{
			return ((streamingPlayer.android.BackgroundAudioPlayer)player).HasPrevious();
		@}

	}
}
