Sequel.migration do
    change do
        create_table(:action_items_users) do
            primary_key :id
            foreign_key :action_item_id, :action_items, :null => false
            foreign_key :user_id, :users, :null => false
        end
    end
end
