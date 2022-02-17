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

  def playlist_length(list)
    if (list.source == 'spotify')
      return get_spotify_playlist_length(list.source_id)
    end
    if (list.source == 'youtube')
      return get_youtube_playlist_length(list.source_id)
    end
  end

  def playlist_songs(list)
    return spt_playlist_songs(list.source_id) if (list.source == 'spotify')
    return yt_playlist_songs(list.source_id) if (list.source == 'youtube')
  end

  def add_songs(songs, list)
    return spt_add_songs(songs, list.source_id) if (list.source == 'spotify')
    return yt_add_songs(songs, list.source_id) if (list.source == 'youtube')
  end

  private

  def spt_playlist_songs_raw(id)
    res =
      RecursiveOpenStruct.new(
        get_spotify("playlists/#{id}/tracks"),
        recurse_over_arrays: true,
      )
    return res.items
  end

  def spt_add_songs(songs, id)
    new_uris = Array.new
    songs.each do |s|
      r =
        RecursiveOpenStruct.new(
          get_spotify(
            'search',
            {
              q: "#{s.name} #{s.artists if defined?(s.artists)}",
              type: 'track',
            },
          ),
          recurse_over_arrays: true,
        )
      if (r.tracks.items.empty?)
        r =
          RecursiveOpenStruct.new(
            get_spotify(
              'search',
              {
                q:
                  "#{s.name.split('(').first} #{s.artists if defined?(s.artists)}",
                type: 'track',
              },
            ),
            recurse_over_arrays: true,
          )
      end
      if (r.tracks.items.empty?)
        r =
          RecursiveOpenStruct.new(
            get_spotify(
              'search',
              {
                q:
                  "#{s.name.split('(').first.split('-').second} #{s.artists if defined?(s.artists)}",
                type: 'track',
              },
            ),
            recurse_over_arrays: true,
          )
      end
      if (r.tracks.items.empty?)
        r =
          RecursiveOpenStruct.new(
            get_spotify(
              'search',
              {
                q:
                  "#{s.name.split('(').first.split('-').second} #{s.name.split('(').first.split('-').second}",
                type: 'track',
              },
            ),
            recurse_over_arrays: true,
          )
      end
      new_uris << r.tracks.items.first.uri if r.tracks.items.first&.uri
    end
    old_uris = spt_playlist_songs_raw(id).collect { |s| s.track.uri }
    r = post_spotify("playlists/#{id}/tracks", { uris: new_uris - old_uris })
  end

  def yt_add_songs(songs, id)
    old_ids =
      @youtube
        .list_playlist_items('snippet', playlist_id: id)
        .items
        .collect { |i| i.snippet.resource_id.video_id }

    new_ids = Array.new
    songs.each do |s|
      r =
        @youtube.list_searches(
          'snippet',
          q: "#{s.name} #{s.artists if defined?(s.artists)}",
          type: 'video',
        )
      v_id = r.items.first.id.video_id
      item = Google::Apis::YoutubeV3::PlaylistItem.new
      snippet = Google::Apis::YoutubeV3::PlaylistItemSnippet.new
      snippet.playlist_id = id
      resource_id = Google::Apis::YoutubeV3::ResourceId.new
      resource_id.kind = 'youtube#video'
      resource_id.video_id = v_id
      snippet.resource_id = resource_id
      item.snippet = snippet
      if (!old_ids.include?(v_id))
        @youtube.insert_playlist_item('snippet', item)
      end
    end
  end

  def spt_playlist_songs(id)
    raw = spt_playlist_songs_raw(id)
    songs = Array.new
    raw.each do |s|
      songs <<
        Helpers::Song.new(
          s.track.name,
          s.track.artists.collect { |a| a.name }.join(','),
        )
    end
    return songs
  end

  def yt_playlist_songs(id)
    res =
      @youtube.list_playlist_items('snippet', max_results: 50, playlist_id: id)
    songs = Array.new
    res.items.each { |i| songs << Helpers::Song.new(i.snippet.title) }
    return songs
  end

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

  def post_spotify(path, body = {})
    token = @user.spotify_token.access_token
    uri = URI::HTTPS.build(host: 'api.spotify.com', path: '/v1/' + path)
    res =
      HTTP
        .headers(
          accept: 'application/json',
          content_type: 'application/json',
          authorization: 'Bearer ' + token,
        )
        .post(uri, json: body)
    if (res.status == 401)
      if (res.parse['error']['message'] == 'The access token expired')
        refresh_spotify_token
        return post_spotify(path, body)
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
