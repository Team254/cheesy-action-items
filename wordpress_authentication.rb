# Copyright 2013 Team 254. All Rights Reserved.
# @author pat@patfairbank.com (Patrick Fairbank)

require "httparty"
require "pathological"
require "json"

require "config/environment"

module CheesyActionItems
  # Helper mixin for third-party authentication using Wordpress.
  module WordpressAuthentication
    def wordpress_cookie
      request.cookies["wordpress_logged_in_3d42b000d2a4a2d18a5508d8ef1e38e4"]
    end

    # Returns a hash of user info if logged in to Wordpress, or nil otherwise.
    def get_wordpress_user_info
      if wordpress_cookie
        response = HTTParty.get("#{WORDPRESS_AUTH_URL}?cookie=#{URI.encode(wordpress_cookie)}")
        return JSON.parse(response.body) if response.code == 200
      end
      return nil
    end
  end
end
