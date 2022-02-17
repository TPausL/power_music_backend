require 'google/apis/youtube_v3'
require 'google/apis/oauth2_v2'
require 'googleauth'
require 'googleauth/stores/file_token_store'

module Helpers::YoutubeHelper
  def self.included(base)
    base.before_action :yt_setup
  end

  def yt_get_playlists
    lists = current_user.youtube_playlists
    if (!lists.any?)
      return yt_fetch_playlists
    else
      return lists
    end
  end

  def yt_fetch_playlists
    res =
      @youtube.list_playlists(
        %w[snippet contentDetails],
        mine: true,
        max_results: 50,
      )
    service_ids = res.items.collect(&:id)
    db_ids =
      current_user.playlists.where(source: 'youtube').collect(&:source_id)
    Playlist.where(source_id: db_ids - service_ids).destroy_all
    res.items.map do |p|
      newList = {
        title: p.snippet.title,
        source: 'youtube',
        source_id: p.id,
        count: p.content_details.item_count,
        image_url: p.snippet.thumbnails.default.url,
      }
      list = current_user.playlists.where(source_id: p.id).first
      if (list)
        list.update(newList)
      else
        list = Playlist.new(newList)
        list.owner = current_user
        list.save
      end
      next list
    end
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
    oauth_service = Google::Apis::Oauth2V2::Oauth2Service.new
    oauth_service.authorization = @authorizer.get_credentials(current_user.id)

    channel = @youtube.list_channels('snippet', mine: true).items.first
    new_user = {
      source: 'youtube',
      id: channel.id,
      email: oauth_service.get_userinfo_v2(fields: 'email').email,
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

  def yt_setup
    scopes = %w[
      https://www.googleapis.com/auth/youtube
      https://www.googleapis.com/auth/userinfo.email
    ]
    token_store =
      Google::Auth::Stores::FileTokenStore.new(file: 'google_store.yaml')
    client_id = Google::Auth::ClientId.from_file('config/google.json')
    @authorizer =
      Google::Auth::UserAuthorizer.new(client_id, scopes, token_store)
    @youtube = Google::Apis::YoutubeV3::YouTubeService.new
    @youtube.authorization = @authorizer.get_credentials(current_user.id)
  end
end
