# Copyright 2013 Team 254. All Rights Reserved.
# @author pat@patfairbank.com (Patrick Fairbank)
#
# The main class of the action items web server.

require "pathological"
require "sinatra/base"

require "config/environment"
require "models"
require "wordpress_authentication"

module CheesyActionItems
  class Server < Sinatra::Base
    include WordpressAuthentication

    set :sessions => true

    # Enforce authentication for all routes except login.
    before do
      unless wordpress_cookie
        # Log the user out if not logged into Wordpress but still has an active session here.
        session[:user_id] = nil
      end

      @user = User[session[:user_id]]
      authenticate! unless ["/login"].include?(request.path)
    end

    def authenticate!
      redirect "/login?redirect=#{request.path}" if @user.nil?
    end

    get "/login" do
      @redirect = params[:redirect] || "/"

      # Authenticate against Wordpress.
      wordpress_user_info = get_wordpress_user_info
      if wordpress_user_info
        # TODO(pat): Stop at this point unless the user is a leader or mentor.
        user = User[wordpress_user_info["id"]]
        unless user
          # Create a new record in the local DB for the user to cache the Wordpress JSON.
          user = User.create(:id => wordpress_user_info["id"], :wordpress_json => wordpress_user_info.to_json)
        else
          # Update the cache of the Wordpress JSON on each login in case it has changed.
          user.update(:wordpress_json => wordpress_user_info.to_json)
        end
        session[:user_id] = user.id
        redirect @redirect
      else
        redirect_path = URI.encode("http://action-items.team254.com/login?redirect=#{@redirect}")
        redirect "http://www.team254.com/wp-login.php?redirect_to=#{redirect_path}"
      end
    end

    get "/" do
      "This page intentionally left blank, #{@user.name}."
    end
  end
end
