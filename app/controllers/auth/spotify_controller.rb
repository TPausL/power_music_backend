class Auth::SpotifyController < ApplicationController
  before_action :doorkeeper_authorize!

  def login
    render json: { 'login': 'test' }
  end
end
