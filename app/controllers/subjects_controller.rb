class SubjectsController < ApplicationController
  before_action :authenticate_user!

  # Load the subject for the current user for these actions
  before_action :set_subject, only: [ :edit, :update, :destroy ]

  # === Create ===
  # Build a new subject for the current user
  # Save and redirect with notification of success
  def create
    @subject = current_user.subjects.new(subject_params)
    if @subject.save
      redirect_to subjects_path, notice: "Subject created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # === Read ===
  # Get all subjects for the current user (sorted by name)
  # Arrange into a nested tree using Ancestry (sorted by name)
  # Build a hash of the count of cases and provisions (collectively entries) per subject
  def index
    @subjects = current_user.subjects.order(:name)
    @tree     = @subjects.arrange(order: :name)
    @entry_counts = CardTemplate
                     .owned_by(current_user)
                     .left_joins(:case_detail, :provision_detail)
                     .where("cases.id IS NOT NULL OR provisions.id IS NOT NULL")
                     .group(:subject_id)
                     .count
  end

  # Get the IDs of a subject and its children
  # Load all acts for the subject/child tree and order by name
  # Load all case_templates that have cases and provisions and order by name
  def show
    session[:last_subject_id] = @subject.id
    subtree_ids = @subject.subtree_ids

    @cases = CardTemplate
      .owned_by(current_user)
      .where(subject_id: subtree_ids, kind: "Case")
      .joins(:case_detail)
      .includes(:subject, :case_detail)
      .order(Arel.sql(<<~SQL.squish))
        LOWER(TRIM(COALESCE(cases.case_name, ''))) ASC,
        card_templates.id ASC
      SQL
    
    tree_ids = @subject.root.subtree_ids

    @acts = (defined?(current_user.acts) ? current_user.acts : Act)
      .where(subject_id: tree_ids)
      .includes(:subject, :provisions)
      .order(Arel.sql("LOWER(TRIM(COALESCE(act_short_name, act_name))) ASC, acts.id ASC"))

    @provisions = CardTemplate
      .owned_by(current_user)
      .where(subject_id: subtree_ids, kind: "Provision")
      .joins(:provision_detail)
      .includes(:subject, :provision_detail)
      .order(Arel.sql(<<~SQL.squish))
        LOWER(TRIM(COALESCE(provisions.act_short_name, provisions.act_name, card_templates.name, ''))) ASC,
        LOWER(TRIM(COALESCE(provisions.provision_ref, ''))) ASC,
        card_templates.id ASC
      SQL
  end

  # === Update ===
  # Render the edit form
  def edit; end

  # Try update when the edit form is submitted or provide an error
  def update
    if @subject.update(subject_params)
      redirect_to subjects_path, notice: "Subject updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # === Destroy ===
  # Delete a subject or proivide an error message
  # Will not delete if subject has sub-topics, Acts, cases, provisions or sessions
  def destroy
    if @subject.children.exists?
      return redirect_to subjects_path,
        alert: "Cannot delete this subject while it has sub-topics. Move or delete them first",
        status: :see_other
    end

  subtree_ids = @subject.subtree_ids

  if Act.where(subject_id: subtree_ids).exists?
    return redirect_to subjects_path,
      alert: "Cannot delete this subject while it has Acts. Delete or move those Acts first",
      status: :see_other
  end

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

  session_items_exist = SessionItem
    .where(item_type: "CardTemplate", item_id: CardTemplate.where(subject_id: subtree_ids).select(:id))
    .exists?

  if session_items_exist
    return redirect_to subjects_path,
      alert: "Cannot delete this subject: one or more Sessions still use its entries. Delete those Sessions first",
      status: :see_other
  end

  if @subject.destroy
    redirect_to subjects_path, notice: "Subject deleted", status: :see_other
  else
    msg = @subject.errors.full_messages.to_sentence.presence || "Could not delete subject."
    redirect_to subjects_path, alert: msg, status: :see_other
  end
end

  private

  # Find the subject by ID for the current user
  def set_subject
    @subject = current_user.subjects.find(params[:id])
  end

  # Ensure only name and parent can be set by the form
  def subject_params
    params.require(:subject).permit(:name, :parent_id)
  end
end
