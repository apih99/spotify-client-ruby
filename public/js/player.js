window.onSpotifyWebPlaybackSDKReady = () => {
  let player;
  let deviceId;
  let accessToken;

  // Fetch the access token from our backend
  fetch('/api/token')
    .then(response => response.json())
    .then(data => {
      if (!data.access_token) {
        throw new Error('No access token available');
      }
      accessToken = data.access_token;
      
      // Initialize the Spotify Player
      player = new Spotify.Player({
        name: 'Web Playback SDK Player',
        getOAuthToken: cb => { cb(accessToken); }
      });

      // Error handling
      player.addListener('initialization_error', ({ message }) => {
        console.error('Failed to initialize:', message);
        handleError('Failed to initialize player');
      });
      
      player.addListener('authentication_error', ({ message }) => {
        console.error('Failed to authenticate:', message);
        window.location.href = '/login';
      });
      
      player.addListener('account_error', ({ message }) => {
        console.error('Failed to validate Spotify account:', message);
        handleError('Premium account required for playback');
      });
      
      player.addListener('playback_error', ({ message }) => {
        console.error('Failed to perform playback:', message);
        handleError('Playback error occurred');
      });

      // Playback status updates
      player.addListener('player_state_changed', state => {
        if (state) {
          updatePlayerState(state);
        }
      });

      // Ready
      player.addListener('ready', ({ device_id }) => {
        console.log('Ready with Device ID', device_id);
        deviceId = device_id;
        document.getElementById('player').classList.add('ready');
        
        // Automatically transfer playback to this device
        transferPlayback(device_id);
      });

      // Not Ready
      player.addListener('not_ready', ({ device_id }) => {
        console.log('Device ID is not ready:', device_id);
        document.getElementById('player').classList.remove('ready');
      });

      // Connect to the player
      player.connect();
    })
    .catch(error => {
      console.error('Spotify Player Error:', error);
      handleError('Failed to initialize Spotify player');
    });

  // UI Controls
  document.getElementById('play-pause').addEventListener('click', () => {
    player.togglePlay();
  });

  document.getElementById('previous').addEventListener('click', () => {
    player.previousTrack();
  });

  document.getElementById('next').addEventListener('click', () => {
    player.nextTrack();
  });

  // Playlist click handlers
  document.addEventListener('DOMContentLoaded', () => {
    const playlistItems = document.querySelectorAll('.playlist-item');
    playlistItems.forEach(item => {
      item.addEventListener('click', () => {
        const playlistId = item.dataset.playlistId;
        playPlaylist(playlistId);
      });
    });
  });

  function updatePlayerState(state) {
    // Update track info
    if (state.track_window.current_track) {
      const track = state.track_window.current_track;
      document.getElementById('current-track-name').textContent = track.name;
      document.getElementById('current-track-artist').textContent = track.artists.map(a => a.name).join(', ');
      document.getElementById('current-track-image').src = track.album.images[0].url;
    }

    // Update play/pause button
    const playPauseButton = document.getElementById('play-pause');
    playPauseButton.textContent = state.paused ? 'Play' : 'Pause';

    // Update progress bar
    if (state.duration && state.position) {
      const progress = (state.position / state.duration) * 100;
      document.getElementById('progress-bar').style.width = `${progress}%`;
    }
  }

  function transferPlayback(deviceId) {
    fetch('/api/player/transfer', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ device_id: deviceId })
    })
    .then(response => {
      if (!response.ok) throw new Error('Failed to transfer playback');
      console.log('Playback transferred successfully');
    })
    .catch(error => {
      console.error('Transfer error:', error);
      handleError('Failed to transfer playback to this device');
    });
  }

  function playPlaylist(playlistId) {
    if (!deviceId) {
      handleError('Playback device not ready');
      return;
    }

    fetch('/api/player/play', {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        device_id: deviceId,
        context_uri: `spotify:playlist:${playlistId}`,
      })
    })
    .catch(error => {
      console.error('Playback error:', error);
      handleError('Failed to start playback');
    });
  }

  function handleError(message) {
    const errorDiv = document.createElement('div');
    errorDiv.className = 'error-message';
    errorDiv.textContent = message;
    document.body.appendChild(errorDiv);
    setTimeout(() => errorDiv.remove(), 5000);
  }
}; 