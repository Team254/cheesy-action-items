Sequel.migration do
    change do
        create_table(:leaders_action_items) do
            primary_key :id
            foreign_key :action_item_id, :action_items
            foreign_key :user_id, :users
        end
    end
end
