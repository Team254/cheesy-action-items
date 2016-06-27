Sequel.migration do
  change do
    alter_table(:users) do
      add_column :name, String, :null => false
      drop_column :wordpress_json
    end
  end
end
