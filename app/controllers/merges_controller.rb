class MergesController < ApplicationController
  include Helpers::ResponseHelper
  include Helpers::SpotifyHelper
  include Helpers::YoutubeHelper
  include Helpers::Validation

  before_action :doorkeeper_authorize!

  before_action except: %i[index create] do
    validate(:merges, :id)
  end

  def index
    if current_user.merges.empty?
      render json: error("You don't have any merges"), status: 404
      return
    end
    render json: success('List of your merges', current_user.merges)
  end

  def show
    render json:
             success("Merge with id #{params['id']}", Merge.find(params['id']))
  end

  def create
    begin
      m = Merge.create(merge_params)
      m.direction = params['direction'] || 'both'
      m.left = current_user.playlists.where(id: params['left'])&.first
      m.right = current_user.playlists.where(id: params['right'])&.first
      m.owner = current_user
      m.save!
      Merge.exec_one(m)
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
    rescue => e
      render json: error('An unknown error occurred', e), status: 400
      return
    end
  end

  def update; end

  def destroy
    current_user.merges.find(params[:id]).destroy
    render json: success('Succesfully deleted merge')
  end
end
