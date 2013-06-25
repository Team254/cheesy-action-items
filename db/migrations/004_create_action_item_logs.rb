Sequel.migration do
  change do
    create_table(:action_item_logs) do
      primary_key :id
      Integer :action_item_id, :null => false
      Integer :user_id, :null => false
      DateTime :changed_at, :null => false
      Text :old_content
      Text :new_content
    end
  end
end
