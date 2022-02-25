require 'googleauth'
require 'googleauth/stores/file_token_store'

class Auth::YoutubeController < ApplicationController
  before_action :doorkeeper_authorize!

  include Helpers::ResponseHelper
  include Helpers::YoutubeHelper

  def initialize
    super
    @scopes = %w[
      https://www.googleapis.com/auth/youtube
      https://www.googleapis.com/auth/userinfo.email
    ]
    @token_store =
      Google::Auth::Stores::FileTokenStore.new(file: 'google_store.yaml')
    @client_id = Google::Auth::ClientId.from_file('config/google.json')
  end

  def login
    if @token_store.load(current_user.id)
      render json:
               error(
                 'Something went wrong authorizing with Youtube',
                 { auth: 'You are already logged in to Youtube!' },
               ),
             status: 400
      return
    end
    authorizer =
      Google::Auth::UserAuthorizer.new(
        @client_id,
        @scopes,
        @token_store,
        params[:redirect_uri],
      )
    url = authorizer.get_authorization_url(base_url: params[:redirect_uri])
    render json:
             success(
               'Please redirect user to following URL and return code here.',
               { redirect_uri: url, code_to: 'http://localhost:3000/auth/youtube/code' },
             )
  end

  def code
    if @token_store.load(current_user.id)
      render json:
               error(
                 'Something went wrong authorizing with Youtube',
                 { auth: 'You are already logged in to Youtube!' },
               ),
             status: 400
      return
    end
    begin
      authorizer =
        Google::Auth::UserAuthorizer.new(
          @client_id,
          @scopes,
          @token_store,
          params[:redirect_uri],
        )
      credentials =
        authorizer.get_and_store_credentials_from_code(
          { user_id: current_user.id, code: params[:code] },
        )
      data = credentials.as_json
      data['source'] = 'youtube'
      data['expires_in'] =
        (DateTime.parse(data['expires_at']).utc - DateTime.now.utc).round
      data['scope'] = data['scope'].join(' ')
      data =
        data.slice(
          'access_token',
          'source',
          'refresh_token',
          'scope',
          'expires_in',
          'source',
          'client_id',
          'client_secret',
        )
      current_user.youtube_token&.delete
      token = ServiceToken.new(data)
      token.source = 'youtube'
      token.owner = current_user
      token.save
      current_user.service_tokens.reload
      yt_setup
      render json: success('Succesfully authorized with Youtube', yt_fetch_user)
    rescue => e
      render json:
               error(
                 'Something went wrong authorizing with Youtube',
                 { from_service: e.message.as_json },
               )
      return
    end
  end
end
