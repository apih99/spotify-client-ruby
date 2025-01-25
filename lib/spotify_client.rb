# frozen_string_literal: true

require 'rest-client'
require 'json'
require 'dotenv'
require 'base64'
require 'uri'
require 'securerandom'
require 'digest'
require 'httparty'
require 'dotenv/load'
require 'webrick'

class SpotifyClient
  include HTTParty
  base_uri 'https://api.spotify.com/v1'

  BASE_URL = 'https://api.spotify.com/v1'
  AUTH_URL = 'https://accounts.spotify.com/authorize'
  TOKEN_URL = 'https://accounts.spotify.com/api/token'
  REDIRECT_URI = 'http://localhost:4567/callback'
  SCOPES = %w[
    user-read-private
    user-read-email
    playlist-read-private
    playlist-read-collaborative
    user-modify-playback-state
    streaming
  ].join(' ')

  attr_accessor :access_token, :code_verifier, :code_challenge
  attr_reader :refresh_token

  def initialize
    @client_id = ENV['SPOTIFY_CLIENT_ID']
    @client_secret = ENV['SPOTIFY_CLIENT_SECRET']
    @access_token = nil
    @refresh_token = nil
    generate_pkce_challenge
  end

  def authenticate
    auth_header = Base64.strict_encode64("#{@client_id}:#{@client_secret}")
    response = HTTParty.post('https://accounts.spotify.com/api/token',
      headers: {
        'Authorization' => "Basic #{auth_header}",
        'Content-Type' => 'application/x-www-form-urlencoded'
      },
      body: {
        grant_type: 'client_credentials'
      }
    )

    if response.success?
      @access_token = response['access_token']
      true
    else
      puts "Authentication failed: #{response.body}"
      false
    end
  end

  def authorization_url
    generate_pkce_challenge unless @code_verifier && @code_challenge
    
    params = {
      client_id: @client_id,
      response_type: 'code',
      redirect_uri: REDIRECT_URI,
      code_challenge_method: 'S256',
      code_challenge: @code_challenge,
      scope: SCOPES
    }
    
    puts "Debug - Authorization Parameters:"
    puts "Client ID: #{@client_id}"
    puts "Redirect URI: #{REDIRECT_URI}"
    puts "Code Challenge: #{@code_challenge}"
    puts "Code Verifier: #{@code_verifier[0..5]}..." # Only show first few characters
    
    "#{AUTH_URL}?#{URI.encode_www_form(params)}"
  end

  def handle_callback(code)
    return false unless @code_verifier

    puts "Attempting token exchange with code: #{code[0..5]}..."
    puts "Using code_verifier: #{@code_verifier[0..5]}..."
    
    response = HTTParty.post(TOKEN_URL,
      headers: {
        'Content-Type' => 'application/x-www-form-urlencoded'
      },
      body: {
        grant_type: 'authorization_code',
        code: code,
        redirect_uri: REDIRECT_URI,
        client_id: @client_id,
        client_secret: @client_secret,
        code_verifier: @code_verifier
      }
    )

    if response.success?
      @access_token = response['access_token']
      @refresh_token = response['refresh_token']
      puts "Token exchange successful!"
      true
    else
      puts "Token exchange failed: #{response.code} - #{response.body}"
      false
    end
  rescue => e
    puts "Token exchange error: #{e.class} - #{e.message}"
    false
  end

  def get_profile
    request(:get, '/me')
  end

  def get_playlists
    request(:get, '/me/playlists')
  end

  def search(query, type = 'track', limit = 20)
    return nil unless @access_token

    response = self.class.get('/search',
      query: {
        q: query,
        type: type,
        limit: limit
      },
      headers: {
        'Authorization' => "Bearer #{@access_token}"
      }
    )

    if response.success?
      response.parsed_response
    else
      puts "Search failed: #{response.body}"
      nil
    end
  end

  def get_devices
    request(:get, '/me/player/devices')
  end

  def transfer_playback(device_id)
    request(:put, '/me/player', {
      device_ids: [device_id],
      play: false
    })
  end

  def play(device_id, context_uri = nil)
    params = {}
    params[:context_uri] = context_uri if context_uri

    request(:put, "/me/player/play?device_id=#{device_id}", params)
  end

  def pause(device_id)
    request(:put, "/me/player/pause?device_id=#{device_id}")
  end

  def get_playback_state
    request(:get, '/me/player')
  end

  private

  def generate_pkce_challenge
    @code_verifier = SecureRandom.urlsafe_base64(64).tr('=', '')
    code_challenge = Digest::SHA256.base64digest(@code_verifier)
    @code_challenge = code_challenge.tr('+/', '-_').tr('=', '')
  end

  def request(method, endpoint, params = {})
    return nil unless @access_token

    headers = {
      'Authorization' => "Bearer #{@access_token}",
      'Content-Type' => 'application/json'
    }

    response = if [:get, :delete].include?(method)
      self.class.get(endpoint, headers: headers)
    else
      self.class.send(method, endpoint,
        body: params.to_json,
        headers: headers
      )
    end

    if response.success?
      response.parsed_response
    else
      puts "Request failed: #{response.code} - #{response.body}"
      nil
    end
  rescue => e
    puts "Request error: #{e.class} - #{e.message}"
    nil
  end
end 