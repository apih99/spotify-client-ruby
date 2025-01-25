# Spotify Web Client

A Ruby-based Spotify Web Client that allows you to browse and play your Spotify playlists using the Spotify Web Playback SDK.

## Features

- OAuth2 authentication with PKCE
- Browse personal playlists
- Web-based playback using Spotify Web Playback SDK
- Automatic device switching
- Play/pause/next/previous controls
- Progress bar for current track
- Modern, Spotify-like interface

## Prerequisites

- Ruby 3.3 or higher
- Bundler
- [Spotify Premium Account](https://www.spotify.com/premium/) (required for playback)
- [Spotify Developer Account](https://developer.spotify.com/dashboard)

## Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd spotify-client
```

2. Install dependencies:
```bash
bundle install
```

3. Create a Spotify Application:
   - Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
   - Click "Create App"
   - Fill in the application details
   - Add `http://localhost:4567/callback` to the Redirect URIs
   - Save your changes

4. Set up environment variables:
   - Copy the example environment file:
     ```bash
     cp .env.example .env
     ```
   - Edit `.env` and add your Spotify API credentials:
     ```env
     SPOTIFY_CLIENT_ID=your_client_id
     SPOTIFY_CLIENT_SECRET=your_client_secret
     ```
   - (Optional) Set a custom session secret:
     ```env
     SESSION_SECRET=your_custom_secret
     ```

## Running the Application

1. Start the server:
```bash
bundle exec rackup -p 4567
```

2. Open your browser and navigate to:
```
http://localhost:4567
```

3. Log in with your Spotify account when prompted

## Project Structure

```
spotify-client/
├── lib/
│   └── spotify_client.rb    # Spotify API client implementation
├── public/
│   ├── css/
│   │   └── style.css       # Application styles
│   └── js/
│       └── player.js       # Web Playback SDK integration
├── views/
│   ├── player.erb          # Main player interface
│   └── error.erb          # Error page template
├── app.rb                  # Sinatra web application
├── config.ru              # Rack configuration
├── Gemfile               # Ruby dependencies
└── README.md             # This file
```

## API Endpoints

### Authentication
- `GET /login` - Initiates the Spotify OAuth2 flow
- `GET /callback` - OAuth2 callback handler
- `GET /logout` - Clears the session

### Player Control
- `GET /api/token` - Get the current access token
- `GET /api/devices` - List available playback devices
- `POST /api/player/transfer` - Transfer playback to a device
- `PUT /api/player/play` - Start/resume playback
- `PUT /api/player/pause` - Pause playback
- `GET /api/player/state` - Get current playback state

### Content
- `GET /api/playlists` - Get user's playlists

## Implementation Details

### Authentication Flow
1. Uses OAuth2 with PKCE (Proof Key for Code Exchange)
2. Generates secure code verifier and challenge
3. Stores PKCE values in session during authentication
4. Exchanges authorization code for access token
5. Maintains session using encrypted cookies

### Playback Control
1. Integrates with Spotify Web Playback SDK
2. Automatically transfers playback to web client
3. Provides real-time playback state updates
4. Handles device switching and playlist selection

## Dependencies

- `sinatra` - Web framework
- `httparty` - HTTP client
- `dotenv` - Environment variable management
- `webrick` - Web server
- `rest-client` - HTTP client for complex requests
- `json` - JSON parsing
- `erb` - Template rendering

## Development Dependencies

- `rspec` - Testing framework
- `webmock` - HTTP request mocking

## Error Handling

- Comprehensive error handling for API requests
- User-friendly error messages
- Automatic session recovery
- Playback state monitoring
- Device availability checking

## Security

- Secure PKCE implementation
- Session encryption
- Environment variable protection
- No client secret exposure to frontend
- Secure token handling

## Browser Compatibility

- Chrome 70+
- Firefox 63+
- Edge 79+
- Safari 12.1+
- Opera 57+

## Known Limitations

- Requires Spotify Premium account for playback
- Web Playback SDK is not supported on mobile browsers
- Some features may require additional Spotify permissions

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Spotify Web API](https://developer.spotify.com/documentation/web-api/)
- [Spotify Web Playback SDK](https://developer.spotify.com/documentation/web-playback-sdk/)
- [Coding Challenges](https://codingchallenges.fyi/challenges/challenge-spotify) 