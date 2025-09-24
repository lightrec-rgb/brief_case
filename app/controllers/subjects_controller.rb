class SubjectsController < ApplicationController
  # check user is authenticated and so can access options
  before_action :authenticate_user!
  before_action :set_subject, only: [ :show, :edit, :update, :destroy ]

  # load subjects for the current user
  def index
    # @tree = current_user.subjects.arrange(order: :name)
    @subjects = current_user.subjects.order(:name)
    @tree     = @subjects.arrange(order: :name)
    @entry_counts = CardTemplate
                     .owned_by(current_user)
                     .left_joins(:case_detail, :provision_detail)
                     .where("cases.id IS NOT NULL OR provisions.id IS NOT NULL")
                     .group(:subject_id)
                     .count
  end

  # build a hierarchial tree using ancestry gem, sorting by name
  def show
    subtree_ids = @subject.subtree_ids

    # Load acts in the whole subtree (so the “Acts” and “Provisions by Act” sections work)
    @acts = Act
              .where(subject_id: subtree_ids)
              .includes(:provisions)                # avoids N+1 when counting/listing
              .order(Arel.sql("LOWER(COALESCE(act_short_name, act_name)) ASC"))

    # Load entries (CardTemplates) that actually have a case or a provision
    @entries = CardTemplate
                .owned_by(current_user)
                .where(subject_id: subtree_ids)
                .left_joins(:case_detail, :provision_detail)
                .includes(:subject, :case_detail, :provision_detail)
                .where("cases.id IS NOT NULL OR provisions.id IS NOT NULL")
                .reorder(Arel.sql(<<~SQL.squish))
                  CASE card_templates.kind
                    WHEN 'Case' THEN LOWER(COALESCE(cases.case_short_name, cases.case_name, card_templates.name, ''))
                    WHEN 'Provision' THEN LOWER(COALESCE(provisions.act_short_name, provisions.act_name, card_templates.name, ''))
                    ELSE LOWER(COALESCE(card_templates.name, ''))
                  END ASC
               SQL
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

  # Guard 1: cannot delete if it has sub-topics
  if @subject.children.exists?
    return redirect_to subjects_path,
      alert: "Cannot delete this subject while it has sub-topics. Move or delete them first",
      status: :see_other
  end

  # Consider the whole subtree so you don’t leave grandchildren behind.
  subtree_ids = @subject.subtree_ids

  # Guard 2: any Acts still in this subject (or descendants)?
  if Act.where(subject_id: subtree_ids).exists?
    return redirect_to subjects_path,
      alert: "Cannot delete this subject while it has Acts. Delete or move those Acts first",
      status: :see_other
  end

  # Guard 3: any real entries (Case/Provision) still present?
  entries_exist = CardTemplate
                    .where(subject_id: subtree_ids)
                    .left_joins(:case_detail, :provision_detail)
                    .where("cases.id IS NOT NULL OR provisions.id IS NOT NULL")
                    .exists?

  if entries_exist
    return redirect_to subjects_path,
      alert: "Cannot delete this subject while it has Cases or Provisions. Delete or move those entries first",
      status: :see_other
  end
  # Guard 4: any SessionItems referencing templates in this subject (or descendants)?
  session_items_exist = SessionItem
    .where(item_type: "CardTemplate", item_id: CardTemplate.where(subject_id: subtree_ids).select(:id))
    .exists?

  if session_items_exist
    return redirect_to subjects_path,
      alert: "Cannot delete this subject: one or more Sessions still use its entries. Delete those Sessions first",
      status: :see_other
  end

  # Safe to delete. (Empty CardTemplate shells will be auto-removed by before_destroy)
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
