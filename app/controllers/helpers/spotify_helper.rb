module Helpers::SpotifyHelper
  def spt_get_playlists
    lists = current_user.spotify_playlists
    if (!lists.any?)
      return spt_fetch_playlists
    else
      return lists
    end
  end

  def spt_fetch_playlists
    user = spt_get_user
    res = get('me/playlists', { 'limit': 50 })
    r =
      RecursiveOpenStruct.new(
        get('me/playlists', { 'limit': 50 }),
        recurse_over_arrays: true,
      )
    service_ids = r.items.collect(&:id)
    db_ids =
      current_user.playlists.where(source: 'spotify').collect(&:source_id)
    Playlist.where(source_id: db_ids - service_ids).destroy_all

    lists =
      res['items'].map do |p|
        if (p['collaborative'] || p['owner']['id'] == user.id)
          newList = {
            title: p['name'],
            source: 'spotify',
            source_id: p['id'],
            count: p['tracks']['total'],
            image_url: p['images'].any? ? p['images']&.first['url'] : nil,
          }
          list = current_user.playlists.where(source_id: p['id']).first
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

  def spt_get_user
    user = current_user.spotify_user
    if (!user)
      return spt_fetch_user
    else
      return user
    end
  end

  def spt_fetch_user
    res = get('me')
    new_user = {
      source: 'spotify',
      id: res['id'],
      email: res['email'],
      name: res['display_name'],
      image_url: res['images'].first['url'],
    }
    spt_user = current_user.spotify_user
    if (spt_user)
      spt_user.update(new_user)
    else
      spt_user = ServiceUser.new(new_user)
      spt_user.user = current_user
      spt_user.save
      current_user.service_connections.reload
    end
    return spt_user
  end

  private

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
      if (res.parse['error']['message'] == 'The access token expired')
        refresh_token
        return get(path, query)
      else
        raise 'User not logged in'
      end
    end
    return res.parse
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
