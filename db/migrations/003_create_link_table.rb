Sequel.migration do
    change do
        create_table(:action_items_users) do
            primary_key :id
            Integer :action_item_id, :null => false
            Integer :user_id, :null => false
        end
    end
end
