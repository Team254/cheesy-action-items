
class ActionItem < Sequel::Model
  many_to_many :users

  def before_save
    unless completion_date.nil?
      days_until_due = ((due_date - completion_date) / 86400).to_i
      if days_until_due >= 4
        self.grade = 1
      elsif days_until_due < 4 && days_until_due >= 0
        self.grade = 0.05 * days_until_due + 0.8
      else
        self.grade = 0.8 * 0.5 ** (-days_until_due.to_f / 7)
      end
    end
    super
  end
end
