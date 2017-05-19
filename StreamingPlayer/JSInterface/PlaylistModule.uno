using Fuse;
using Uno;
using Uno.UX;
using Fuse.Scripting;
using Fuse.Platform;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace StreamingPlayer
{
	[UXGlobalModule]
	public class PlaylistModule : NativeModule
	{	
		static IStreamingPlayer _player;

		static PlaylistModule _instance;
		
		NativeEvent _statusChanged;
		NativeEvent _currentTrackChanged;
		NativeEvent _hasNextChanged;
		NativeEvent _hasPreviousChanged;

		public PlaylistModule()
		{
			if (_instance != null) return;
			_instance = this;
			
			if (_player == null) {
				_player = StreamingPlayer.New();
			}
				
			Resource.SetGlobalKey(_instance, "PlaylistPlayer");
			AddMember(new NativeFunction("next", (NativeCallback)Next));
			AddMember(new NativeFunction("previous", (NativeCallback)Previous));
			AddMember(new NativeFunction("addTrack", (NativeCallback)AddTrack));
			AddMember(new NativeFunction("setPlaylist", (NativeCallback)SetPlaylist));

			AddMember(new NativeProperty<bool, bool>("hasNext", GetHasNext, null, null));
			AddMember(new NativeProperty<bool, bool>("hasPrevious", GetHasPrevious, null, null));

			AddMember(new NativeFunction("play", (NativeCallback)Play));
			AddMember(new NativeFunction("pause", (NativeCallback)Pause));
			AddMember(new NativeFunction("resume", (NativeCallback)Resume));
			AddMember(new NativeFunction("stop", (NativeCallback)Stop));
			AddMember(new NativeFunction("seek", (NativeCallback)Seek));

			AddMember(new NativeProperty<PlayerStatus,string>("status", GetStatus, null, PlayerStatusConverter.Convert));
			AddMember(new NativeProperty<double,double>("duration", GetDuration));
			AddMember(new NativeProperty<double,double>("progress", GetProgress));
			AddMember(new NativeProperty<Track,Fuse.Scripting.Object>("currentTrack", GetCurrentTrack, null, Track.ToJSObject));

			_statusChanged = new NativeEvent("statusChanged");
			AddMember(_statusChanged);

			_currentTrackChanged = new NativeEvent("currentTrackChanged");
			AddMember(_currentTrackChanged);
			
			_hasNextChanged = new NativeEvent("hasNextChanged");
			AddMember(_hasNextChanged);
			
			_hasPreviousChanged = new NativeEvent("hasPreviousChanged");
			AddMember(_hasPreviousChanged);
			
			_player.StatusChanged += OnStatusChanged;
			_player.CurrentTrackChanged += OnCurrentTrackChanged;
			_player.HasNextChanged += OnHasNextChanged;
			_player.HasPreviousChanged += OnHasPreviousChanged;

			Fuse.Platform.Lifecycle.EnteringForeground += OnEnteringForeground;
		}
		
		void OnEnteringForeground(ApplicationState state)
		{
			debug_log("Entering foreground: state: " + _player.Status);
			OnStatusChanged(_player.Status);
			OnHasNextChanged(_player.HasNext);
			OnHasPreviousChanged(_player.HasPrevious);
			OnCurrentTrackChanged();
		}

		bool CanCallBackToJS
		{
			get
			{
				return Fuse.Platform.Lifecycle.State == ApplicationState.Foreground
					|| Fuse.Platform.Lifecycle.State == ApplicationState.Interactive;
			}
		}

		void OnStatusChanged(PlayerStatus status)
		{
			if (CanCallBackToJS)
				_statusChanged.RaiseAsync(status.Stringify());
		}

		void OnHasNextChanged(bool n)
		{
			if (CanCallBackToJS)
				_hasNextChanged.RaiseAsync(n);
		}

		void OnHasPreviousChanged(bool p)
		{
			if (CanCallBackToJS)
				_hasPreviousChanged.RaiseAsync(p);
		}

		void OnCurrentTrackChanged()
		{
			if (CanCallBackToJS) {
				_currentTrackChanged.RaiseAsync();
			}
		}

		public object Next(Context c, object[] args)
		{
			debug_log("Next was called from JS");
			return _player.Next();
		}

		public object Previous(Context c, object[] args)
		{
			return _player.Previous();
		}

		public object AddTrack(Context c, object[] args)
		{
			foreach (var a in args)
			{
				var track = Marshal.ToType<Track>(a);
				if (a != null)
					_player.AddTrack(track);
			}
			return null;
		}

		public object SetPlaylist(Context c, object[] args)
		{
			//SetPlaylist(Track[] tracks)
			var trackArray = args[0] as IArray;
			if (trackArray != null)
			{
				List<Track> tracks = new List<Track>();
				for (var i = 0; i < trackArray.Length; i++)
				{
					var a = trackArray[i];
					var track = Marshal.ToType<Track>(a);
					if (a != null)
						_player.AddTrack(track);
				}
				_player.SetPlaylist(tracks.ToArray());
			}
			else
				_player.SetPlaylist(null);
			return null;
		}

		Track GetCurrentTrack() { return _player.CurrentTrack; }

		bool GetHasNext() { return _player.HasNext; }

		bool GetHasPrevious() { return _player.HasPrevious; }

		PlayerStatus GetStatus() { return _player.Status; }

		double GetDuration() { return _player.Duration; }

		double GetProgress() { return _player.Progress; }

		object Play(Context c, object[] args)
		{
			var track = args.ValueOrDefault<Track>(0, null);
			if (track == null)
				throw new Exception("Play needs a {name,url,streamUrl} argument");
			_player.Play(track);
			return null;
		}

		object Resume(Context c, object[] args)
		{
			if (_player == null)
				throw new Exception("Player was null!, nothing to resume.");
			_player.Resume();
			return null;
		}

		object Seek(Context c, object[] args)
		{
			_player.Seek(args.ValueOrDefault<double>(0, 0.0));
			return null;
		}

		object[] Pause(Context c, object[] args)
		{
			_player.Pause();
			return null;
		}

		object[] Stop(Context c, object[] args)
		{
			_player.Stop();
			return null;
		}
	}
}
