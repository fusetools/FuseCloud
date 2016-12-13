using Uno;
using Uno.UX;
using Uno.Threading;
using Fuse.Scripting;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace StreamingPlayer
{
	public enum PlayerStatus
	{
		Stopped, Loading, Playing, Paused, Error
	}

	static class PlayerStatusConverter
	{
		public static string Stringify(this PlayerStatus status)
		{
			switch (status)
			{
				case PlayerStatus.Stopped:
					return "Stopped";
				case PlayerStatus.Loading:
					return "Loading";
				case PlayerStatus.Playing:
					return "Playing";
				case PlayerStatus.Paused:
					return "Paused";
				case PlayerStatus.Error:
					return "Error";
				default:
					return null;
			}
		}

		public static string Convert(Context c, PlayerStatus s)
		{
			return s.Stringify();
		}
	}

	public delegate void StatusChangedHandler(PlayerStatus status);

	public interface IStreamingPlayer
	{
		void Play(Track track);
		void Seek(double toProgress);
		void Pause();
		void Resume();
		void Stop();
		double Duration { get; }
		double Progress { get; }

		PlayerStatus Status { get; }
		event StatusChangedHandler StatusChanged;

		int Next();
		int Previous();
		void AddTrack(Track track);
		void SetPlaylist(Track[] tracks);

		Track CurrentTrack { get; }
		bool HasNext { get; }
		bool HasPrevious { get; }

		event Action CurrentTrackChanged;
		event Action<bool> HasNextChanged;
		event Action<bool> HasPreviousChanged;
	}
}
