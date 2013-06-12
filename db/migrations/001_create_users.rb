Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id
      Text :wordpress_json, :null => false
    end
  end
end
