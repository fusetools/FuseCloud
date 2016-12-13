
package streamingPlayer.android;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.os.Parcel;
import android.os.RemoteException;


public final class BackgroundAudioPlayer
{
	
	private LocalConnection _connection;
	private BackgroundAudioService _service;
	private BackgroundAudioService.LocalBinder _binder;

	private com.foreign.Uno.Action_int _statusCallback;
	private com.foreign.Uno.Action _hasPrevNextChanged;
	private com.foreign.Uno.Action _currentTrackChanged;

	public BackgroundAudioPlayer(Activity a,
								 com.foreign.Uno.Action_int statusCallback,
								 com.foreign.Uno.Action hasPrevNextChanged,
								 com.foreign.Uno.Action currentTrackChanged)
	{
		_connection = new LocalConnection();
		Intent intent = new Intent(a, BackgroundAudioService.class);
		intent.setAction(BackgroundAudioService.ACTION_PLAY);
		a.bindService(intent, _connection, Context.BIND_AUTO_CREATE);
		a.startService(intent);
		_statusCallback = statusCallback;
		_hasPrevNextChanged = hasPrevNextChanged;
		_currentTrackChanged = currentTrackChanged;
	}
	   	
	public void Resume(){
		if (isConnected()){
			_service.Resume();
		}
	}

	private boolean _pendingPlay = false;
	private Track _pendingTrack;
	public void Play(Track track)
	{
		if (isConnected()){
			_service.Play(track);
			_pendingPlay = false;
		} else {
			_pendingPlay = true;
			_pendingTrack = track;
		}
	}
	
	public void Stop()
	{
		if (isConnected()) {
			_service.Stop();
		}
	}

	public void Pause()
	{
		if (isConnected()) {
			_service.Pause();
		}
	}

	public void Seek(int milliseconds)
	{
		if (isConnected()) {
			_service.Seek(milliseconds);
		}
	}

	public double GetCurrentPosition(){
		if (isConnected()) {
			return _service.GetCurrentPosition();
		}
		return 0.0;
	}

	public double GetCurrentTrackDuration(){
		if (isConnected()) {
			return _service.GetCurrentTrackDuration();
		}
		return 0.0;
	}

	public Track GetCurrentTrack() {
		if (isConnected()) {
			return _service.GetCurrentTrack();
		}
		return null;
	}


	Track[] _tempPlaylist;
	public void SetPlaylist(Track[] tracks){
		if (isConnected()) {
			_service.SetPlaylist(tracks);
		} else {
			_tempPlaylist = tracks;
		}
	}

	public void connectedToBackgroundService() {
		if (_tempPlaylist != null) {
			SetPlaylist(_tempPlaylist);
			_tempPlaylist = null;
		}
		if (_pendingPlay)
			Play(_pendingTrack);
		OnHasPrevNextChanged();
	}

	public void AddTrack(Track track){
		if (isConnected()){
			_service.AddTrack(track);
		}
	}

	public int Next()
	{
		if (isConnected()){
			_service.Next();
			return _service.CurrentTrackIndex();
		}
		return 0;
	}

	public int Previous()
	{
		if (isConnected()){
			_service.Previous();
			return _service.CurrentTrackIndex();
		}
		return 0;
	}

	public boolean HasNext() {
		if (isConnected()){
			return _service.HasNext();
		}
		return false;
	}

	public boolean HasPrevious() {
		if (isConnected()){
			return _service.HasPrevious();
		}
		return false;
	}

	public void OnHasPrevNextChanged(){
		if (_hasPrevNextChanged != null) {
			_hasPrevNextChanged.run();
		}
	}

	public void OnCurrentTrackChanged(){
		if (_currentTrackChanged != null) {
			_currentTrackChanged.run();
		}
	}

	private boolean isConnected() {
		return _binder != null;
	}

	public void statusChanged(AndroidPlayerState state) {
		int intState = 0;
		switch (state) {
		case Idle: intState = 0; Logger.Log("AndroidStatus: Idle"); break;
		case Initialized: intState = 1; Logger.Log("AndroidStatus: Initialized"); break;
		case Preparing: intState = 2; Logger.Log("AndroidStatus: Preparing"); break;
		case Prepared: intState = 3; Logger.Log("AndroidStatus: Prepared"); break;
		case Started: intState = 4; Logger.Log("AndroidStatus: Started"); break;
		case Stopped: intState = 5; Logger.Log("AndroidStatus: Stopped"); break;
		case Paused: intState = 6; Logger.Log("AndroidStatus: Paused"); break;
		case PlaybackCompleted: intState = 7; Logger.Log("AndroidStatus: PlaybackCompleted"); break; 
		case Error: intState = 8; Logger.Log("AndroidStatus: Error"); break;
		case End: intState = 9; Logger.Log("AndroidStatus: End"); break;
		}
		if (_statusCallback != null) {
			_statusCallback.run(intState);
		}
	}

	private class LocalConnection implements ServiceConnection
	{
		public void onServiceConnected(ComponentName className, IBinder service)
		{
			// Because we have bound to an explicit
			// service that is running in our own process, we can
			// cast its IBinder to a concrete class and directly access it.
			_binder = (BackgroundAudioService.LocalBinder) service;
			_service = _binder.getService();
			_service.setBackgroundPlayer(BackgroundAudioPlayer.this);
			connectedToBackgroundService();
		}
		// Called when the connection with the service disconnects unexpectedly
		public void onServiceDisconnected(ComponentName className)
		{
			Logger.Log("Music player handle service disconnection");
		}
	}
}
