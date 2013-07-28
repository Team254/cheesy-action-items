Sequel.migration do
  change do
    alter_table(:action_items) do
      add_column :created_by_user_id, Integer, :null => false
    end
  end
end
