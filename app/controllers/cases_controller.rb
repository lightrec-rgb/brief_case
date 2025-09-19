class CasesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_case, only: [:show, :edit, :update, :destroy]

  # get all cases for the current user
  def index
    @cases = Case.index_for(current_user) 
  end

  # build a unsaved case when a user accesses the new form (GET)
  def new
    @case = Case.build_for(user: current_user, attrs: {})
    @subjects_for_select = current_user.subjects.order(:name).pluck(:name, :id)
  end

  # save a case when submitting the new form (POST)
  def create
    @case = Case.build_for(user: current_user, attrs: {})
    if @case.save_from(case_params)
      redirect_to entry_path(@case.card_template), notice: "Case created.", status: :see_other
    else
      @subjects_for_select = current_user.subjects.order(:name).pluck(:name, :id)
      render :new, status: :unprocessable_entity
    end
  end

  # show a case (GET)
  def show; end

  # render edit form including subject dropdown (GET)
  def edit
    @subjects_for_select = current_user.subjects.order(:name).pluck(:name, :id)
  end

  # updates when the edit form is submitted or provide an error (PATCH/PUT)
  def update
    if @case.update_from(case_params)
      redirect_to entry_path(@case.card_template), notice: "Case updated.", status: :see_other
    else
      @subjects_for_select = current_user.subjects.order(:name).pluck(:name, :id)
      render :edit, status: :unprocessable_entity
    end
  end

  # deletes the case or proivides error message
  def destroy
    subject_id = @case.card_template.subject_id
    @case.destroy
    redirect_to entries_path(subject_id: subject_id), notice: "Case deleted.", status: :see_other
  end

  private

  # find the case by ID for the current user
  def set_case
    @case = Case.index_for(current_user).find(params[:id])
  end

  # ensure only case fields can be mass-assigned
  def case_params
    params.require(:case).permit(
      :subject_id, :full_citation, :case_name, :case_short_name,
      :material_facts, :issue, :key_principle
    )
  end
end
