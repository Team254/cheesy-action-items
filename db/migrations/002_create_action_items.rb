Sequel.migration do
    change do
        create_table(:action_items) do
            primary_key :id
            Text :title, :null => false
            Text :deliverables, :null => false
            Integer :user_id, :null => false
            Date :start_date, :null => false
            Date :due_date, :null => false
            Date :completion_date
            Float :grade
            Text :mentor, :null => false
        end
    end
end
