require 'google/apis/youtube_v3'
require 'google/apis/oauth2_v2'
require 'googleauth'
require 'googleauth/stores/file_token_store'

class Helpers::MergeHelper
  def initialize(user)
    @user = user
    if (user.youtube_user)
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
      @youtube.authorization = @authorizer.get_credentials(user.id)
    end
  end

  def get_playlist_length(list)
    if (list.source == 'spotify')
      return get_spotify_playlist_length(list.source_id)
    end
    if (list.source == 'youtube')
      return get_youtube_playlist_length(list.source_id)
    end
  end

  private

  def get_youtube_playlist_length(id)
    return(
      @youtube
        .list_playlist_items('id', playlist_id: id)
        .page_info
        .total_results
    )
  end

  def get_spotify(path, query = {})
    token = @user.spotify_token.access_token
    uri =
      URI::HTTPS.build(
        host: 'api.spotify.com',
        path: '/v1/' + path,
        query: query.to_query,
      )
    res =
      HTTP
        .headers(accept: 'application/json', authorization: 'Bearer ' + token)
        .get(uri)
    if (res.status == 401)
      if (res.parse['error']['message'] == 'The access token expired')
        refresh_spotify_token
        return get_spotify(path, query)
      else
        raise 'User not logged in'
      end
    end
    return res.parse
  end

  def get_spotify_playlist_length(id)
    res = get_spotify("playlists/#{id}")
    return res['tracks']['total']
  end

  def refresh_spotify_token
    t = @user.spotify_token
    if t.updated_at.to_datetime + t.expires_in.seconds < DateTime.now.utc
      token_uri =
        URI::HTTPS.build(host: 'accounts.spotify.com', path: '/api/token')
      res =
        HTTP
          .basic_auth(
            user: Rails.application.credentials.spotify.client_id,
            pass: Rails.application.credentials.spotify.client_secret,
          )
          .headers(
            accept: 'application/json',
            #'content-type': 'application/x-www-form-urlencoded',
          )
          .post(
            token_uri,
            form: {
              grant_type: 'refresh_token',
              refresh_token: t.refresh_token,
              client_id: Rails.application.credentials.spotify.client_id,
            },
          )
      if res.status == 200
        t.update(res.parse.except('token_type'))
        return true
      else
        return false
      end
    end
  end
end
