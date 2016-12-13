using Uno;
using Uno.UX;
using Uno.Threading;
using Fuse;
using Fuse.Scripting;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace StreamingPlayer
{
	extern(!Android && !iOS) class StreamingPlayerDummyImpl : IStreamingPlayer
	{
		double _duration = 200.0;
		public double Duration { get { return _duration; } private set { _duration = value; } }
		double _progress = 0.0;
		public double Progress { get { return _progress; } private set { _progress = value; } }

		PlayerStatus _status;
		public PlayerStatus Status
		{
			get { return _status; }
			set
			{
				_status = value;
				OnStatusChanged();
			}
		}

		void UpdatePlayer()
		{
			Progress += 0.1;
			if (Status == PlayerStatus.Playing || Status == PlayerStatus.Paused)
				Timer.Wait(0.1, UpdatePlayer);
		}

		void DoneLoading()
		{
			Status = PlayerStatus.Playing;
			Timer.Wait(0.1, UpdatePlayer);
		}

		public void Play(Track track)
		{
			Status = PlayerStatus.Loading;
			Timer.Wait(1.0, DoneLoading);
		}

		public void Resume()
		{
			Status = PlayerStatus.Playing;
			Timer.Wait(0.1, UpdatePlayer);
		}

		public void Pause()
		{
			Status = PlayerStatus.Paused;
		}

		public void Stop()
		{
			Progress = 0.0;
			Status = PlayerStatus.Stopped;
		}

		public void Seek(double toProgress)
		{
			Progress = toProgress * Duration;
		}



		public event StatusChangedHandler StatusChanged;
		void OnStatusChanged()
		{
			if (StatusChanged != null){
				StatusChanged(Status);
			}
		}

		public int Next() { return 0; }
		public int Previous() { return 0; }
		public void AddTrack(Track track) { }
		public void SetPlaylist(Track[] tracks) {}


		public Track _currentTrack;
		public Track CurrentTrack { get { return _currentTrack; } }
		public bool HasNext { get { return true; } }
		public bool HasPrevious { get { return true; } }

		public event Action CurrentTrackChanged;
		public event Action<bool> HasNextChanged;
		public event Action<bool> HasPreviousChanged;
	}
}
