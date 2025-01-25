require 'spec_helper'
require_relative '../lib/spotify_client'

RSpec.describe SpotifyClient do
  let(:client) { SpotifyClient.new }
  let(:client_id) { ENV['SPOTIFY_CLIENT_ID'] }
  let(:client_secret) { ENV['SPOTIFY_CLIENT_SECRET'] }

  describe '#initialize' do
    it 'creates a new client with credentials from environment' do
      expect(client.instance_variable_get(:@client_id)).to eq(client_id)
      expect(client.instance_variable_get(:@client_secret)).to eq(client_secret)
      expect(client.instance_variable_get(:@access_token)).to be_nil
    end

    it 'generates PKCE challenge' do
      expect(client.instance_variable_get(:@code_verifier)).not_to be_nil
      expect(client.instance_variable_get(:@code_challenge)).not_to be_nil
    end
  end

  describe '#authenticate' do
    let(:access_token) { 'mock_access_token' }
    let(:token_response) do
      {
        access_token: access_token,
        token_type: 'Bearer',
        expires_in: 3600
      }
    end

    before do
      stub_request(:post, 'https://accounts.spotify.com/api/token')
        .with(
          headers: {
            'Authorization' => /^Basic .+$/,
            'Content-Type' => 'application/x-www-form-urlencoded'
          },
          body: {
            grant_type: 'client_credentials'
          }
        )
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: token_response.to_json
        )
    end

    it 'successfully authenticates with client credentials' do
      expect(client.authenticate).to be true
      expect(client.access_token).to eq(access_token)
    end
  end

  describe '#get_playlists' do
    let(:access_token) { 'mock_access_token' }
    let(:playlists_response) do
      {
        'items' => [
          {
            'name' => 'Test Playlist',
            'tracks' => { 'total' => 10 },
            'images' => [{ 'url' => 'http://example.com/image.jpg' }]
          }
        ]
      }
    end

    before do
      client.instance_variable_set(:@access_token, access_token)
      stub_request(:get, "#{SpotifyClient::BASE_URL}/me/playlists")
        .with(headers: { 'Authorization' => "Bearer #{access_token}" })
        .to_return(status: 200, body: playlists_response.to_json)
    end

    it 'successfully fetches playlists' do
      playlists = client.get_playlists
      expect(playlists).to eq(playlists_response)
      expect(playlists['items'].first['name']).to eq('Test Playlist')
    end
  end

  describe '#authorization_url' do
    it 'generates correct authorization URL' do
      url = client.authorization_url
      expect(url).to start_with(SpotifyClient::AUTH_URL)
      expect(url).to include("client_id=#{client_id}")
      expect(url).to include('response_type=code')
      expect(url).to include('redirect_uri=')
      expect(url).to include('code_challenge_method=S256')
      expect(url).to include('code_challenge=')
    end
  end

  describe '#handle_callback' do
    let(:code) { 'auth_code' }
    let(:access_token) { 'mock_access_token' }
    let(:refresh_token) { 'mock_refresh_token' }
    let(:token_response) do
      {
        'access_token' => access_token,
        'refresh_token' => refresh_token,
        'token_type' => 'Bearer',
        'expires_in' => 3600
      }
    end

    before do
      stub_request(:post, SpotifyClient::TOKEN_URL)
        .to_return(status: 200, body: token_response.to_json)
    end

    it 'successfully handles the callback code' do
      expect(client.handle_callback(code)).to be true
      expect(client.access_token).to eq(access_token)
      expect(client.instance_variable_get(:@refresh_token)).to eq(refresh_token)
    end
  end
end 