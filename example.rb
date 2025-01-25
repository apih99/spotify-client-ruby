require_relative 'lib/spotify_client'

# Create a new client instance
client = SpotifyClient.new

# Authenticate
if client.authenticate
  puts "Successfully authenticated!"
  
  # Search for a track
  results = client.search('Bohemian Rhapsody', 'track', 5)
  
  if results
    tracks = results['tracks']['items']
    puts "\nSearch results for 'Bohemian Rhapsody':"
    tracks.each do |track|
      puts "#{track['name']} by #{track['artists'].map { |a| a['name'] }.join(', ')}"
    end
  end
else
  puts "Authentication failed!"
end 