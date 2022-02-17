class ApplicationController < ActionController::API
  before_action :set_user
  respond_to :json

  def set_user
    token_string = request.headers['Authorization']&.sub('Bearer ', '')
    return nil if !token_string
    user_id = Doorkeeper::AccessToken.by_token(token_string)&.resource_owner_id
    return nil if !user_id
    user = User.find(user_id)
    sign_in(user)
  end
end
