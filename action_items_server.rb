# Copyright 2013 Team 254. All Rights Reserved.
# @author pat@patfairbank.com (Patrick Fairbank)
#
# The main class of the action items web server.

require "cheesy-common"
require "pathological"
require "sinatra/base"
require "time"

require "models"

module CheesyActionItems
  class Server < Sinatra::Base
    use Rack::Session::Cookie, :key => "rack.session", :expire_after => 3600

    # Enforce authentication for all routes.
    before do
      member = session[:member]
      if member.nil?
        member = CheesyCommon::Auth.get_user(request)
        if member.nil?
          redirect "#{CheesyCommon::Config.members_url}?site=action-items&path=#{request.path}"
        else
          session[:member] = member
        end
      end

      # Create or get the app-specific user model.
      @user = User[member.id]
      unless @user
        @user = User.create(:id => member.id, :name => member.name_display)
      end
      @user.member = member
    end

    get "/" do
      redirect "/action_items/open"
    end

    get "/action_items/open" do
      erb :open_action_items
    end

    get "/action_items/open/partial" do
      erb :action_item_list,
          :locals => { :action_items => ActionItem.where(:completion_date => nil).order(:id) }
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
      if params[:completion_date] && @user.member.has_permission?("ACTION_ITEMS_EDIT")
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
      halt(400, "Invalid action item.") if @action_item.nil?
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
                                      :mentor => params[:mentor], :created_by_user_id => @user.id)
      leaders = params[:leaders].split(",").each do |user_id|
        action_item.add_user(User[user_id])
      end
      redirect "/action_items/open"
    end

    get "/stats" do
      erb :stats
    end

    get "/log" do
      halt(400, "Mentors only.") unless @user.member.has_permission?("ACTION_ITEMS_EDIT")
      erb :log
    end

    get "/api/leaders" do
      content_type :json
      User.all.map(&:wordpress_fields).to_json
    end

    post "/api/edit" do
      # TODO: param checking, throw a 400
      # TODO: prettier client response upon success
      if params[:name] == "completion_date" && !@user.member.has_permission?("ACTION_ITEMS_EDIT")
        halt(400, "Only mentors can close an action item.")
      end
      ActionItem.where(:id => params[:pk]).update(params[:name] => params[:value])
      halt(200, "OK")
    end
  end
end
