module Helpers::SpotifyHelper
  def spt_fetch_playlists
    puts 'test'
    user = get_user
    res = get('me/playlists', { 'limit': 50 })
    lists =
      res['items'].map do |p|
        if (p['collaborative'] || p['owner']['id'] == user.id)
          newList = {
            title: p['name'],
            source: 'spotify',
            source_id: p['id'],
            count: p['tracks']['total'],
            image_url: p['images'].first['url'],
          }
          list = Playlist.find_by(source_id: p['id'])
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
    return lists.compact
  end

  def get(path, query = {})
    token = current_user.spotify_token.access_token
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
      refresh_token
      return get(path, query)
    end
    return res.parse
  end

  def get_user()
    res = get('me')
    return Helpers::HelperUser.new(res)
  end

  def refresh_token
    t = current_user.spotify_token
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
