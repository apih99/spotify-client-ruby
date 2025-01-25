require 'sinatra'
require 'sinatra/json'
require 'securerandom'
require_relative 'lib/spotify_client'

class SpotifyWebApp < Sinatra::Base
  configure do
    enable :sessions
    set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }
    set :public_folder, 'public'
    set :show_exceptions, false
  end

  error do
    content_type :json
    status 500
    { error: env['sinatra.error'].message }.to_json
  end

  def client
    @client ||= SpotifyClient.new
  end

  before do
    if session[:access_token] && request.path_info != '/logout'
      client.access_token = session[:access_token]
    end
  end

  get '/' do
    if session[:access_token]
      begin
        @playlists = client.get_playlists
        if @playlists
          erb :player
        else
          session.clear
          redirect '/login'
        end
      rescue => e
        puts "Error fetching playlists: #{e.message}"
        session.clear
        redirect '/login'
      end
    else
      redirect '/login'
    end
  end

  get '/login' do
    auth_url = client.authorization_url
    session[:code_verifier] = client.code_verifier
    session[:code_challenge] = client.code_challenge
    redirect auth_url
  end

  get '/callback' do
    if params[:code]
      client.code_verifier = session[:code_verifier]
      client.code_challenge = session[:code_challenge]
      
      if client.handle_callback(params[:code])
        session[:access_token] = client.access_token
        session.delete(:code_verifier)
        session.delete(:code_challenge)
        redirect '/'
      else
        session.clear
        erb :error, locals: { message: 'Authentication failed!' }
      end
    else
      session.clear
      erb :error, locals: { message: 'No authorization code received!' }
    end
  end

  get '/api/playlists' do
    content_type :json
    playlists = client.get_playlists
    if playlists
      playlists.to_json
    else
      status 401
      { error: 'Failed to fetch playlists' }.to_json
    end
  end

  get '/api/token' do
    content_type :json
    if session[:access_token]
      { access_token: session[:access_token] }.to_json
    else
      status 401
      { error: 'No access token available' }.to_json
    end
  end

  get '/logout' do
    session.clear
    redirect '/login'
  end

  get '/api/devices' do
    content_type :json
    devices = client.get_devices
    if devices
      devices.to_json
    else
      status 401
      { error: 'Failed to fetch devices' }.to_json
    end
  end

  post '/api/player/transfer' do
    content_type :json
    data = JSON.parse(request.body.read)
    if client.transfer_playback(data['device_id'])
      { success: true }.to_json
    else
      status 400
      { error: 'Failed to transfer playback' }.to_json
    end
  end

  put '/api/player/play' do
    content_type :json
    data = JSON.parse(request.body.read)
    if client.play(data['device_id'], data['context_uri'])
      { success: true }.to_json
    else
      status 400
      { error: 'Failed to start playback' }.to_json
    end
  end

  put '/api/player/pause' do
    content_type :json
    data = JSON.parse(request.body.read)
    if client.pause(data['device_id'])
      { success: true }.to_json
    else
      status 400
      { error: 'Failed to pause playback' }.to_json
    end
  end

  get '/api/player/state' do
    content_type :json
    state = client.get_playback_state
    if state
      state.to_json
    else
      status 400
      { error: 'Failed to get playback state' }.to_json
    end
  end
end 