# Copyright 2013 Team 254. All Rights Reserved.
# @author pat@patfairbank.com (Patrick Fairbank)
#
# Represents a user account on the system.

class User < Sequel::Model
  many_to_many :action_items
  unrestrict_primary_key

  attr_accessor :member

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
