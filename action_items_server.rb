# Copyright 2013 Team 254. All Rights Reserved.
# @author pat@patfairbank.com (Patrick Fairbank)
#
# The main class of the action items web server.

require "pathological"
require "sinatra/base"
require "time"

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
        redirect_path = URI.encode("http://action-items.team254.com:9003/login?redirect=#{@redirect}")
        redirect "http://www.team254.com/wp-login.php?redirect_to=#{redirect_path}"
      end
    end

    get "/" do
      redirect "/action_items"
    end

    get "/action_items" do
      erb :action_items
      #"This page intentionally left blank, #{@user.name}."
    end

    get "/action_items/:id" do
      @action_item = ActionItem[params[:id]]
      halt(400, "Invalid action item.") if @action_item.nil?
      erb :action_item
    end

    get "/action_items/:id/edit" do
      @action_item = ActionItem[params[:id]]
      halt(400, "Invalid action item,") if @action_item.nil?
      erb :edit_action_item
    end

    post "/action_items/:id/edit" do
      @action_item = ActionItem[params[:id]]
      halt(400, "Invalid action item.") if @action_item.nil?

      @action_item.title = params[:title] if params[:title]
      @action_item.deliverables = params[:deliverables] if params[:deliverables]
      # don't think this works: @action_item.leaders = params[:leaders] if params[:leaders]
      @action_item.start_date = params[:start_date] if params[:start_date]
      @action_item.due_date = params[:due_date] if params[:due_date]
      @action_item.completion_date = params[:completion_date] if params[:completion_date]
      @action_item.grade = params[:grade] if params[:grade]
      @action_item.mentor = params[:mentor] if params[:mentor]
      @action_item.save
      redirect "/action_items/#{params[:id]}"
    end

    get "/new_action_item" do
      erb :new_action_item
    end

    post "/action_items" do
      halt(400, "Missing title.") if params[:title].nil?
      halt(400, "Missing deliverables.") if params[:deliverables].nil?
      halt(400, "Missing leaders.") if params[:leaders].nil?
      halt(400, "Missing due date.") if params[:due_date].nil?
      halt(400, "Missing mentors.") if params[:mentor].nil?
      action_item = ActionItem.create(:title => params[:title], :deliverables => params[:deliverables],
                                      :due_date => params[:due_date], :mentor => params[:mentor])
      action_item.start_date = Time.now.utc.to_s
      action_item.save
      leaders = params[:leaders].split(",").each do |user_id|
        action_item.add_user(User[user_id])
      end
      redirect "/action_items/#{action_item.id}"
    end

    get "/api/leaders" do
      erb :leader_list
    end

  end
end
