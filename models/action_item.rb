
class ActionItem < Sequel::Model
    many_to_many :leaders_action_items
    many_to_many :users
end
