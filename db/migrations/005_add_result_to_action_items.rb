Sequel.migration do
  change do
    alter_table(:action_items) do
      add_column :result, String, :text => true
    end
  end
end
