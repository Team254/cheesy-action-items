Sequel.migration do
    change do
        create_table(:leaders_action_items) do
            primary_key :action_item
            Integer :user_id, :null => false
        end
    end
end
