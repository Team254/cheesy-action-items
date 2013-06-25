
class ActionItemLog < Sequel::Model
  many_to_one :action_item
  many_to_one :user
end
