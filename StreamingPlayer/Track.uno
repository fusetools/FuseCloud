using Fuse;
using Uno;
using Uno.UX;
using Fuse.Scripting;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace StreamingPlayer
{

	public class Track
	{
		public readonly int Id;
		public readonly string Name;
		public readonly string Artist;
		public readonly string Url;
		public readonly string ArtworkUrl;
		public readonly double Duration;

		public Track(int id, string name, string artist, string url, string artworkUrl, double duration)
		{
			Id = id;
			Name = name;
			Artist = artist;
			Url = url;
			ArtworkUrl = artworkUrl;
			Duration = duration;
		}

		public override bool Equals(object obj)
		{
			var t = obj as Track;
			if (t != null)
			{
				if (t.Id == Id
					&& t.Name == Name
					&& t.Artist == Artist
					&& t.Url == Url)
					return true;
			}
			return false;
		}

		public override string ToString()
		{
			return "Track:"+Id+": Name: " + Name + ", Artist: " + Artist + ", Url: " + Url + ", ArtworkUrl: " + ArtworkUrl + ", Duration: " + Duration;
		}

		public static Fuse.Scripting.Object ToJSObject(Context c, Track t)
		{
			if (t == null)
				return null;
			var obj = c.NewObject();
			obj["id"] = t.Id;
			obj["name"] = t.Name;
			obj["artist"] = t.Artist;
			obj["url"] = t.Url;
			obj["artworkUrl"] = t.ArtworkUrl;
			obj["duration"] = t.Duration;
			return obj;
		}
	}

	extern(Android) static class TrackAndroidImpl
	{
			
		[Foreign(Language.Java)]
		public static int GetId(Java.Object t)
		@{
			streamingPlayer.android.Track track = (streamingPlayer.android.Track)t;
			return track.Id;
		@}
		
		[Foreign(Language.Java)]
		public static string GetName(Java.Object t)
		@{
			streamingPlayer.android.Track track = (streamingPlayer.android.Track)t;
			return track.Name;
		@}

		[Foreign(Language.Java)]
		public static string GetArtist(Java.Object t)
		@{
			streamingPlayer.android.Track track = (streamingPlayer.android.Track)t;
			return track.Artist;
		@}
		
		[Foreign(Language.Java)]
		public static string GetUrl(Java.Object t)
		@{
			streamingPlayer.android.Track track = (streamingPlayer.android.Track)t;
			return track.Url;
		@}
		
		[Foreign(Language.Java)]
		public static string GetArtworkUrl(Java.Object t)
		@{
			streamingPlayer.android.Track track = (streamingPlayer.android.Track)t;
			return track.ArtworkUrl;
		@}
		
		[Foreign(Language.Java)]
		public static double GetDuration(Java.Object t)
		@{
			streamingPlayer.android.Track track = (streamingPlayer.android.Track)t;
			return track.Duration;
		@}
		
	}

	class TrackConverter : Marshal.IConverter
	{
		public bool CanConvert(Type t)
		{
			return t == typeof(Track);
		}

		public object TryConvert(Type t, object o)
		{
			if (CanConvert(t))
			{
				var jsObject = (Fuse.Scripting.Object)o;
				var id = Marshal.ToInt(jsObject["id"]);
				var name = jsObject["name"].ToString();
				var artist = jsObject["artist"].ToString();
				var url = jsObject["url"].ToString();
				var artworkUrl = jsObject["artworkUrl"].ToString();
				var duration = Marshal.ToDouble(jsObject["duration"]);
				return new Track(id,name,artist,url,artworkUrl,duration);
			}
			return null;
		}
	}
}
