class CardTemplatesController < ApplicationController
  before_action :authenticate_user!

  # Load the subject for the current user for these actions
  before_action :set_card, only: [ :show, :edit, :update, :destroy ]
  before_action :set_return_subject_id, only: [ :show, :edit, :update, :destroy ]

  # === Create ===
  # Identify kind and build a new card_template with presets
  # Call build_detail method so case and provision subforms fields exist
  # Set card as an alias for the views
  def new
    @subject = current_user.subjects.find_by(id: params[:subject_id])
    kind = params[:kind].presence || "Case"
    @entry   = CardTemplate.new(user: current_user, subject: @subject, kind: kind)
    build_detail_for(@entry)
    @card = @entry
  end

  # Look up subject and build a card_template
  def create
    @subject = current_user.subjects.find(card_params[:subject_id])
    @entry   = CardTemplate.new(card_params.merge(user: current_user))

    if @entry.save
      redirect_to entries_path(subject_id: @subject.id), notice: "Entry created", status: :see_other
    else
      build_detail_for(@entry)
      @card = @entry
      render :new, status: :unprocessable_entity
    end
  end

  # === Read ===
  # Load the current user's subjects and pick the last one (or first alphabetically)
  # Get all IDs for active subject and children and build entries list (cases and provisions)
  # Order case by case name, provisions by Act name
  # Load Acts in the subtree and order them by Act name
  def index
    @subjects = current_user.subjects.order(:name)

    if params[:subject_id].present?
      @subject = current_user.subjects.find_by(id: params[:subject_id])
      session[:last_subject_id] = @subject&.id
    else
      @subject = current_user.subjects.find_by(id: session[:last_subject_id]) || @subjects.first
    end

    @entries =
    if @subject
      subtree_ids = @subject.subtree_ids

      CardTemplate.owned_by(current_user)
                  .where(subject_id: subtree_ids)
                  .left_joins(:case_detail, :provision_detail)
                  .includes(:subject, :case_detail, provision_detail: :act)
                  .where("cases.id IS NOT NULL OR provisions.id IS NOT NULL")
                  .reorder(Arel.sql(<<~SQL.squish))
                    CASE card_templates.kind
                      WHEN 'Case'      THEN LOWER(COALESCE(cases.case_short_name, cases.case_name, card_templates.name, ''))
                      WHEN 'Provision' THEN LOWER(COALESCE(provisions.act_short_name, provisions.act_name, card_templates.name, ''))
                      ELSE LOWER(COALESCE(card_templates.name, ''))
                    END ASC
                  SQL
    else
      CardTemplate.none
    end

    if @subject
      tree_ids = @subject.subtree_ids

      @acts = current_user.acts
                          .where(subject_id: tree_ids)
                          .includes(:subject, :provisions)
                          .order(:act_name, :year, :jurisdiction)
    else
      @acts = Act.none
    end
  end

  # Make entry and card aliases for views
  def show
    @entry = @card
  end

  # === Update ===
  # Make entry and card aliases for edit
  # Call build_detail method so case and provision subforms fields exist
  def edit
    @entry = @card
    build_detail_for(@entry)
  end

  # Update with strong parameters
  def update
    if @card.update(card_params)
      redirect_to entries_path(subject_id: @return_subject_id), notice: "Entry updated", status: :see_other
    else
      build_detail_for(@card)
      render :edit, status: :unprocessable_entity
    end
  end

  # === Destroy ===
  # Delete the card_template and redirect back to subject list
  def destroy
    @card.destroy!
    redirect_to entries_path(subject_id: @return_subject_id), notice: "Deleted", status: :see_other
  end

  private
  #  Find the card_template for the current user
  def set_card
    @card = CardTemplate.owned_by(current_user)
                        .includes(:subject, :case_detail, provision_detail: :act)
                        .find(params[:id])
  end

  # Determine which subject to return back to when clicking on the link
  def set_return_subject_id
    @return_subject_id =
      if params[:subject_id].present? &&
         current_user.subjects.exists?(id: params[:subject_id])
        params[:subject_id]
      elsif session[:last_subject_id].present? &&
            current_user.subjects.exists?(id: session[:last_subject_id])
        session[:last_subject_id]
      else
        @card.subject_id
      end
  end

  # Ensure nested detail exists so form fields render
  def build_detail_for(entry)
    case entry.kind
    when "Case"    then entry.build_case_detail    unless entry.case_detail
    when "Provision" then entry.build_provision_detail unless entry.provision_detail
    end
  end

  # Strong paramaters to whitelist, including nested attributes for cases and provisions
  def card_params
    params.require(:card_template).permit(
      :subject_id,
      :kind,
      case_detail_attributes:      [ :id, :case_name, :case_short_name, :full_citation, :material_facts, :issue, :key_principle ],
      provision_detail_attributes: [ :id, :act_name, :act_short_name, :jurisdiction, :year, :provision_ref, :summary, :provision_text ]
    )
  end
end
