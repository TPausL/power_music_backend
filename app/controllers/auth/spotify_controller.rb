class Auth::SpotifyController < ApplicationController
  before_action :doorkeeper_authorize!

  include Helpers::SpotifyHelper
  include Helpers::ResponseHelper

  def login
    if current_user.spotify_token
      render json:
               error(
                 'Something went wrong authorizing with Spotify',
                 { auth: 'You are already logged in to Spotify!' },
               ),
             status: 400
      return
    end
    auth_uri =
      URI::HTTPS.build(
        host: 'accounts.spotify.com',
        path: '/authorize',
        query: {
          response_type: 'code',
          client_id: Rails.application.credentials.spotify.client_id,
          scope:
            %w[
              user-read-email
              user-read-private
              user-top-read
              playlist-read-private
              playlist-modify-public
              playlist-modify-private
              playlist-read-collaborative
            ].join(','),
          redirect_uri: params[:redirect_uri],
          state: generate_state(16),
        }.to_query,
      )
    render json: { 'redirect_to': auth_uri }
  end

  def code
    if current_user.spotify_token
      render json:
               error(
                 'Something went wrong authorizing with Spotify',
                 { auth: 'You are already logged in to Spotify!' },
               ),
             status: 400
      return
    end
    token_uri =
      URI::HTTPS.build(host: 'accounts.spotify.com', path: '/api/token')
    res =
      HTTP
        .basic_auth(
          user: Rails.application.credentials.spotify.client_id,
          pass: Rails.application.credentials.spotify.client_secret,
        )
        .headers(accept: 'application/json')
        .post(
          token_uri,
          form: {
            grant_type: 'authorization_code',
            code: params[:code],
            redirect_uri: params[:redirect_uri],
          },
        )
    if (res.status == 200)
      spt = SpotifyToken.new(res.parse.except('token_type'))
      spt.owner = current_user
      spt.save
      current_user.reload_spotify_token
      render json:
               success(
                 'Succesfully authorized with Spotify',
                 spt_fetch_user.to_builder,
               )
    else
      render json:
               error(
                 'Something went wrong authorizing with Spotify',
                 { from_service: res.parse['error']['message'] },
               ),
             status: res.status
    end
  end

  private

  def generate_state(number)
    charset = Array('A'..'Z') + Array('a'..'z')
    Array.new(number) { charset.sample }.join
  end
end
