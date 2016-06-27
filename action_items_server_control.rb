# Copyright 2013 Team 254. All Rights Reserved.
# @author pat@patfairbank.com (Patrick Fairbank)
#
# Script for starting/stopping the action items server.

require "bundler/setup"
require "daemons"
require "pathological"
require "thin"

pwd = Dir.pwd
Daemons.run_proc("action_items_server", :monitor => true) do
  Dir.chdir(pwd)  # Fix working directory after daemons sets it to /.
  require "action_items_server"

  Thin::Server.start("0.0.0.0", CheesyCommon::Config.port, CheesyActionItems::Server)
end
