class MergesController < ApplicationController
  include Helpers::ResponseHelper
  include Helpers::SpotifyHelper
  include Helpers::YoutubeHelper

  def index
    render json: success('List of your merges', current_user.merges)
  end

  def test
    yt_fetch_playlists
    spt_fetch_playlists
  end

  def create
    begin
      m = Merge.new
      m.left = current_user.playlists.where(id: params['left'])&.first
      m.right = current_user.playlists.where(id: params['right'])&.first
      m.owner = current_user
      m.save!
      render json: success('Succesfully created merge', m)
      return
    rescue ActiveRecord::RecordNotUnique => e
      render json: error('Merge already exists'), status: 409
    rescue ActiveRecord::RecordInvalid => e
      if (e.message.include? 'Right')
        render json: error('Right Playlist does not exist'), status: 404
        return
      elsif (e.message.include? 'Left')
        render json: error('Left Playlist does not exist'), status: 404
        return
      end
      render json: error('An unknown error occurred', e), status: 400
      return
    rescue e
      render json: error('An unknown error occurred', e), status: 400
      return
    end
  end
end
