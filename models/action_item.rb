
class ActionItem < Sequel::Model
    one_to_many :leaders_action_items
    many_to_many :users
end
