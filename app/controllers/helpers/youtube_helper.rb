require 'google/apis/youtube_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

module Helpers::YoutubeHelper
  def yt_setup
    scopes = ['https://www.googleapis.com/auth/youtube']
    token_store =
      Google::Auth::Stores::FileTokenStore.new(file: 'google_store.yaml')
    client_id = Google::Auth::ClientId.from_file('config/google.json')
    authorizer =
      Google::Auth::UserAuthorizer.new(client_id, scopes, token_store)
    @youtube = Google::Apis::YoutubeV3::YouTubeService.new
    @youtube.authorization = authorizer.get_credentials(current_user.id)
  end

  def yt_get_user
    user = current_user.youtube_user
    if (!user)
      return yt_fetch_user
    else
      return user
    end
  end

  def yt_fetch_user
    channel = @youtube.list_channels('snippet', mine: true).items.first
    new_user = {
      source: 'youtube',
      id: channel.id,
      #todo get proper email adress
      email: current_user.email,
      name: channel.snippet.title,
      image_url: channel.snippet.thumbnails.default.url,
    }
    yt_user = current_user.youtube_user
    if (yt_user)
      yt_user.update(new_user)
    else
      yt_user = ServiceUser.new(new_user)
      yt_user.user = current_user
      yt_user.save
      current_user.service_connections.reload
    end
    return yt_user
  end
end
