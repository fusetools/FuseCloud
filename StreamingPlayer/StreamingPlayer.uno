using Uno;
using Uno.UX;
using Uno.Threading;
using Fuse;
using Fuse.Scripting;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace StreamingPlayer
{
	public class StreamingPlayer
	{
		static IStreamingPlayer _current;
		public static IStreamingPlayer Current
		{
			get { return _current; }
			private set { _current = value; }
		}
		

		public static IStreamingPlayer New()
		{
			if defined(Android)
			{
				_current = new StreamingPlayerAndroidImpl();
			}
			else if defined(iOS)
			{
				_current = new StreamingPlayeriOSImpl();
			}
			else
			{
				_current = new StreamingPlayerDummyImpl();
			}

			if (!Marshal.CanConvertClass(typeof(Track)))
				Marshal.AddConverter(new TrackConverter());

			return _current;
		}
	}
}
