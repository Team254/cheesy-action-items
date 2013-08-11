
class ActionItem < Sequel::Model
  many_to_many :users
  many_to_one :created_by_user, :class => :User, :key => :created_by_user_id

  def before_save
    self.grade = current_grade(completion_date) unless completion_date.nil?
    super
  end

  def current_grade(date_to = Time.now)
    days_until_due = ((due_date - date_to) / 86400).to_i
    if days_until_due >= 4
      grade = 1.1
    elsif days_until_due < 4 && days_until_due >= 0
      grade = 0.025 * days_until_due + 1
    else
      grade = 0.5 ** (-days_until_due.to_f / 7)
    end
    grade
  end

  def to_json
    { :id => id, :title => title, :deliverables => deliverables, :start_date => start_date,
      :due_date => due_date, :completion_date => completion_date, :grade => grade, :mentor => mentor,
      :users => users.map(&:name) }.to_json
  end
end
