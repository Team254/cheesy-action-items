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
        # Only allow leaders and mentors past this point.
        unless wordpress_user_info["mentor"] == 1 || wordpress_user_info["leader"] == 1
          halt(403, "Error: must be a leader or mentor.")
        end

        wordpress_user_info.delete("signature")  # MySQL can't store the Unicode properly.
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
        redirect_path = URI.encode("#{BASE_ADDRESS}/login?redirect=#{@redirect}")
        redirect "http://www.team254.com/wp-login.php?redirect_to=#{redirect_path}"
      end
    end

    get "/" do
      redirect "/action_items/open"
    end

    get "/action_items/open" do
      erb :open_action_items
    end

    get "/action_items/completed" do
      erb :completed_action_items
    end

    get "/action_items/by_leader" do
      erb :by_leader_action_items
    end

    get "/action_items/:id/edit" do
      @action_item = ActionItem[params[:id]]
      halt(400, "Invalid action item,") if @action_item.nil?
      erb :edit_action_item
    end

    post "/action_items/:id/edit" do
      @action_item = ActionItem[params[:id]]
      halt(400, "Invalid action item.") if @action_item.nil?
      before_json = @action_item.to_json

      @action_item.title = params[:title] if params[:title]
      @action_item.deliverables = params[:deliverables] if params[:deliverables]
      @action_item.start_date = params[:start_date] if params[:start_date]
      @action_item.due_date = params[:due_date] if params[:due_date]
      if params[:completion_date] && @user.is_mentor?
        @action_item.completion_date = params[:completion_date]
      end
      @action_item.grade = params[:grade] if params[:grade]
      @action_item.mentor = params[:mentor] if params[:mentor]
      @action_item.result = params[:result] if params[:result]
      @action_item.save

      if params[:leaders]
        @action_item.remove_all_users
        leaders = params[:leaders].split(",").each do |user_id|
          @action_item.add_user(User[user_id])
        end
      end

      # Save the before and after serialization of the action item to the logging table.
      after_json = @action_item.to_json
      unless after_json == before_json
        ActionItemLog.create(:action_item_id => @action_item.id, :user_id => @user.id,
                             :changed_at => Time.now, :old_content => before_json, :new_content => after_json)
      end

      redirect "/action_items/open"
    end

    get "/action_items/:id/delete" do
      @action_item = ActionItem[params[:id]]
      halt(400, "Invalid action item,") if @action_item.nil?
      erb :delete_action_item
    end

    post "/action_items/:id/delete" do
      @action_item = ActionItem[params[:id]]
      halt(400, "Invalid action item.") if @action_item.nil?
      before_json = @action_item.to_json
      @action_item.delete

      # Log the deletion of the action item.
      ActionItemLog.create(:action_item_id => @action_item.id, :user_id => @user.id, :changed_at => Time.now,
                           :old_content => before_json, :new_content => "deleted")

      redirect "/action_items/open"
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
                                      :start_date => Time.now, :due_date => params[:due_date],
                                      :mentor => params[:mentor])
      leaders = params[:leaders].split(",").each do |user_id|
        action_item.add_user(User[user_id])
      end
      redirect "/action_items/open"
    end

    get "/stats" do
      erb :stats
    end

    get "/api/leaders" do
      content_type :json
      User.all.map(&:wordpress_fields).to_json
    end

    post "/api/edit" do
      # TODO: param checking, throw a 400
      # TODO: prettier client response upon success
      if params[:name] == "completion_date" && !@user.is_mentor?
        halt(400, "Only mentors can close an action item.")
      end
      ActionItem.where(:id => params[:pk]).update(params[:name] => params[:value])
      halt(200, "OK")
    end
  end
end
