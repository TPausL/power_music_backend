class PlaylistsController < ApplicationController
  include Helpers::ResponseHelper
  include Helpers::Validation
  include Helpers::SpotifyHelper
  include Helpers::YoutubeHelper

  before_action only: :show do |c|
    c.validate(:playlists, :id)
  end

  def index
    if current_user.playlists.empty?
      render json: error("You don't have any playlists"), status: 404
      return
    end
    lists =
      if params[:source]
        current_user.playlists.where(source: params[:source])
      else
        current_user.playlists
      end
    render json: success('List of your playlists', lists.order(:source, :title))
  end

  def show
    render json:
             success(
               "Playlist with id '#{params[:id]}'",
               current_user.playlists.find(params[:id]),
             )
    return
  end

  def fetch
    s = params[:source]
    if (!s)
      yt_fetch_playlists
      spt_fetch_playlists
      render json:
               success(
                 'Succesfully fetched playlists from all services',
                 current_user.playlists,
               )
      return
    elsif (current_user.playlists.distinct.pluck(:source).include? s)
      spt_fetch_playlists if (s == 'spotify')
      yt_fetch_playlists if (s == 'youtube')
      render json:
               success(
                 "Succesfully fetched playlists from #{s}",
                 current_user.playlists.where(source: s),
               )
      return
    else
      render json: error("There are no playlists from #{s}")
    end
  end
end
