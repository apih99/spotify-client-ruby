require_relative 'lib/spotify_client'
require 'webrick'

client = SpotifyClient.new

# Start the local server for OAuth callback
server = WEBrick::HTTPServer.new(
  Port: 4567,
  Logger: WEBrick::Log.new(File.open('NUL', 'w')),
  AccessLog: []
)

# Handle the OAuth callback
server.mount_proc '/callback' do |req, res|
  code = req.query['code']
  if code
    success = client.handle_callback(code)
    if success
      res.body = "Authentication successful! You can close this window."
      server.shutdown
    else
      res.body = "Authentication failed! Please try again."
    end
  else
    res.body = "No authorization code received!"
  end
end

# Get the authorization URL and prompt user to visit it
auth_url = client.authorization_url
puts "Please visit this URL to authorize the application:"
puts auth_url
puts "\nWaiting for authorization..."

# Start the server and wait for the callback
trap('INT') { server.shutdown }
server.start

# After authorization, fetch and display playlists
if client.access_token
  puts "\nFetching your playlists..."
  playlists = client.get_playlists
  
  if playlists && playlists['items']
    puts "\nYour Playlists:"
    playlists['items'].each do |playlist|
      puts "\nName: #{playlist['name']}"
      puts "Total Tracks: #{playlist['tracks']['total']}"
      if playlist['images'] && !playlist['images'].empty?
        puts "Cover Image: #{playlist['images'].first['url']}"
      end
      puts "------------------------"
    end
  else
    puts "Failed to fetch playlists!"
  end
else
  puts "Failed to get access token!"
end 