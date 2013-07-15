# Copyright 2013 Team 254. All Rights Reserved.
# @author pat@patfairbank.com (Patrick Fairbank)
#
# Represents a user account on the system.

require "json"

class User < Sequel::Model
  many_to_many :action_items
  unrestrict_primary_key

  def wordpress_fields
    @wordpress_fields ||= JSON.parse(wordpress_json)
  end

  # Convenience method to allow access to Wordpress JSON fields as if they were member variables.
  def method_missing(method, *args, &block)
    field = method.to_s
    return wordpress_fields[field] if wordpress_fields.include?(field)
    raise NoMethodError.new("undefined method '#{method}' for #{self}")
  end

  def is_leader?
    wordpress_fields["leader"] == 1
  end

  def is_mentor?
    wordpress_fields["mentor"] == 1
  end

  def open_action_items
    action_items.select { |item| item.completion_date.nil? }
  end

  def completed_action_items
    action_items.select { |item| !item.completion_date.nil? }
  end

  def sorted_action_items
    [open_action_items.sort_by(&:due_date), completed_action_items.sort_by(&:due_date)].flatten
  end

  def grade
    items = completed_action_items
    items.inject(0) { |sum, item| sum + item.grade.to_f } / items.size * 100 rescue 0
  end
end
