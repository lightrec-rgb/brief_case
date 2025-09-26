class CasesController < ApplicationController
  before_action :authenticate_user!

  # Load the case for the current user for these actions
  before_action :set_case, only: [ :show, :edit, :update, :destroy ]

  # === Create ===
  # Build an unsaved case when a user accesses the new form
  def new
    @case = Case.build_for(user: current_user, attrs: {})
    @subjects_for_select = current_user.subjects.order(:name).pluck(:name, :id)
  end

  # Build a new case and save it it. Redirect to entries page or provide an error
  def create
    @case = Case.build_for(user: current_user, attrs: {})
    if @case.save_from(case_params)
      redirect_to entry_path(@case.card_template), notice: "Case created", status: :see_other
    else
      @subjects_for_select = current_user.subjects.order(:name).pluck(:name, :id)
      render :new, status: :unprocessable_entity
    end
  end

  # === Read ===
  # Load a list of the current user's cases
  def index
    @cases = Case.index_for(current_user)
  end

  # Placeholder show action
  def show; end

  # === Update ===
  # Render edit form including subject dropdown
  def edit
    @subjects_for_select = current_user.subjects.order(:name).pluck(:name, :id)
  end

  # Updates when the edit form is submitted or provide an error
  def update
    if @case.update_from(case_params)
      redirect_to entry_path(@case.card_template), notice: "Case updated", status: :see_other
    else
      @subjects_for_select = current_user.subjects.order(:name).pluck(:name, :id)
      render :edit, status: :unprocessable_entity
    end
  end

  # === Destroy ===
  # Deletes the case and redirect back to subject list
  def destroy
    subject_id = @case.card_template.subject_id
    @case.destroy
    redirect_to entries_path(subject_id: subject_id), notice: "Case deleted", status: :see_other
  end

  private

  # Find the case by ID for the current user
  def set_case
    @case = Case.index_for(current_user).find(params[:id])
  end

  # Ensure only case fields can be assigned
  def case_params
    params.require(:case).permit(
      :subject_id, :full_citation, :case_name, :case_short_name,
      :material_facts, :issue, :key_principle
    )
  end
end
