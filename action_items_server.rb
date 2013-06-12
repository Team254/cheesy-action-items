# Copyright 2013 Team 254. All Rights Reserved.
# @author pat@patfairbank.com (Patrick Fairbank)
#
# The main class of the action items web server.

require "pathological"
require "sinatra/base"

require "config/environment"

module CheesyActionItems
  class Server < Sinatra::Base
    get "/" do
      "This page intentionally left blank."
    end
  end
end
