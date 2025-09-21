class SubjectsController < ApplicationController
  # check user is authenticated and so can access options
  before_action :authenticate_user!
  before_action :set_subject, only: [ :show, :edit, :update, :destroy ]

  # load subjects for the current user
  def index
    @tree = current_user.subjects.arrange(order: :name)
  end

 # build a hierarchial tree using ancestry gem, sorting by name
 def show
  subtree_ids = @subject.subtree_ids
  @entries = CardTemplate
               .owned_by(current_user)
               .where(subject_id: subtree_ids)
               .for_kind("Case")
               .left_joins(:case_detail)
               .includes(:subject)
               .order(Arel.sql("LOWER(COALESCE(cases.case_name, '')) ASC"))
end

  # build a unsaved subject when a user access the new form (GET)
  def new
    @subject = current_user.subjects.new
  end

  # save a subject when submitting the new form (POST)
  def create
    @subject = current_user.subjects.new(subject_params)
    if @subject.save
      redirect_to subjects_path, notice: "Subject created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # render edit form (GET)
  def edit; end

  # updates when the edit form is submitted or provide an error (PATCH/PUT)
  def update
    if @subject.update(subject_params)
      redirect_to subjects_path, notice: "Subject updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

 # deletes the subject or proivides error message if it still has child records
 def destroy
  @subject = current_user.subjects.find(params[:id])

  # Guard 1: cannot delete if it has sub-subjects
  if @subject.children.exists?
    return redirect_to subjects_path,
      alert: "Cannot delete this subject while it has sub-topics. Move or delete them first.",
      status: :see_other
  end

  # Guard 2: cannot delete if it still has cases/templates
  if @subject.card_templates.exists?
    return redirect_to subjects_path,
      alert: "Cannot delete this subject while it has cases. Move or delete those cases first.",
      status: :see_other
  end

  # Safe to delete
  if @subject.destroy
    redirect_to subjects_path, notice: "Subject deleted", status: :see_other
  else
    msg = @subject.errors.full_messages.to_sentence.presence || "Could not delete subject."
    redirect_to subjects_path, alert: msg, status: :see_other
  end
end

  # find the subject by ID for the current user
  def set_subject
    @subject = current_user.subjects.find(params[:id])
  end

  # ensure only name and parent can be updated
  def subject_params
    params.require(:subject).permit(:name, :parent_id)
  end
end
