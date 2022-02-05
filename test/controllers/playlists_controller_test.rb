require "test_helper"

class PlaylistsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get playlists_index_url
    assert_response :success
  end
end
