package streamingPlayer.android;

public class Track {
	public final int Id;
	public final String Name;
	public final String Artist;
	public final String Url;
	public final String ArtworkUrl;
	public final double Duration;

	public Track(int id,
				 String name,
				 String artist,
				 String url,
				 String artworkUrl,
				 double duration) {
		this.Id = id;
		this.Name = name;
		this.Artist = artist;
		this.Url = url;
		this.ArtworkUrl = artworkUrl;
		this.Duration = duration;
	}

	@Override
	public boolean equals(Object obj)
	{
		if (this == null) return false;
		if (this == obj) return true;
		if (this.getClass() != obj.getClass()) return false;
		// Class name is Employ & have lastname
		Track t = (Track) obj;
		
		return this.Name.equals(t.Name) &&
			this.Artist.equals(t.Artist) &&
			this.Url.equals(t.Url);
	}
}
