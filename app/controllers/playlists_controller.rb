class PlaylistsController < ApplicationController
  before_action :doorkeeper_authorize!

  def index
    render json: Playlist.all
  end

  def create
    render json: current_user
  end
end
