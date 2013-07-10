
class ActionItem < Sequel::Model
  many_to_many :users

  def before_save
    unless completion_date.nil?
      days_until_due = ((due_date - completion_date) / 86400).to_i
      if days_until_due >= 4
        self.grade = 1.1
      elsif days_until_due < 4 && days_until_due >= 0
        self.grade = 0.025 * days_until_due + 1
      else
        self.grade = 0.5 ** (-days_until_due.to_f / 7)
      end
    end
    super
  end

  def to_json
    { :id => id, :title => title, :deliverables => deliverables, :start_date => start_date,
      :due_date => due_date, :completion_date => completion_date, :grade => grade, :mentor => mentor,
      :users => users.map(&:name) }.to_json
  end
end
