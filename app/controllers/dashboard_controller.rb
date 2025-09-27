class DashboardController < ApplicationController
  # Counts for dashboard page
  def index
    @subjects_count   = current_user.subjects.count
    @acts_count       = current_user.acts.count
    @cases_count      = CardTemplate.owned_by(current_user).left_joins(:case_detail).where("cases.id IS NOT NULL").count
    @provisions_count = CardTemplate.owned_by(current_user).left_joins(:provision_detail).where("provisions.id IS NOT NULL").count
    @only_subject_id  = (@subjects_count == 1 ? current_user.subjects.pick(:id) : nil)
    @entries_count    = @cases_count + @provisions_count
  end
end
