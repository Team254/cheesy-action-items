# Copyright 2013 Team 254. All Rights Reserved.
# @author pat@patfairbank.com (Patrick Fairbank)
#
# Script for starting/stopping the action items server.

require "daemons"
require "pathological"
require "thin"

Daemons.run_proc("action_items_server", :monitor => true) do
  require "action_items_server"

  Thin::Server.start("0.0.0.0", PORT, CheesyActionItems::Server)
end
