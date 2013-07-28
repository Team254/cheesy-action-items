
class ActionItemLog < Sequel::Model
  many_to_one :action_item
  many_to_one :user

  def diff
    return "deleted" if new_content == "deleted"
    old_fields = JSON.parse(old_content)
    new_fields = JSON.parse(new_content)
    old_fields.keys.each do |key|
      if old_fields[key] == new_fields[key]
        old_fields.delete(key)
        new_fields.delete(key)
      end
    end
    Set.new(old_fields.keys + new_fields.keys).map do |key|
      "#{key}: #{old_fields[key].inspect} => #{new_fields[key].inspect}"
    end.join(", ")
  end
end
