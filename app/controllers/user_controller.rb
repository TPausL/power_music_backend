class UserController < ApplicationController

    include Helpers::ResponseHelper

    before_action :doorkeeper_authorize!


    def index 
        render json: success("Logged in as #{current_user.name}", current_user)
    end
end
