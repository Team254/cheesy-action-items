Sequel.migration do
    change do
        create_table(:action_items) do
            primary_key :id
            String :title, :null => false
            Text :deliverables, :null => false
            DateTime :start_date, :null => false
            DateTime :due_date, :null => false
            DateTime :completion_date
            Float :grade
            String :mentor, :null => false
        end
    end
end
