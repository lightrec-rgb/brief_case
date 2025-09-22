class CardTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_card, only: [ :show, :edit, :update, :destroy ]

  # load current user's subjects and pick the active one (or first)
  # build the entries list for the subject
  def index
    @subjects = current_user.subjects.order(:name)
    @subject  = @subjects.find_by(id: params[:subject_id]) || @subjects.first

    @entries = if @subject
      subtree_ids = @subject.subtree_ids
      CardTemplate.owned_by(current_user)
                  .where(subject_id: subtree_ids)
                  .for_kind("Case")
                  .left_joins(:case_detail)
                  .includes(:subject, :case_detail)
                  .order(Arel.sql("LOWER(COALESCE(cases.case_name, '')) ASC"))
    else
      CardTemplate.none
    end
  end

  # require subject ID to create a new entry
  # set up a new card_template with presets
  # build the case so UI form shows fields
  def new
    @subject = current_user.subjects.find(params[:subject_id])
    @entry   = CardTemplate.new(user: current_user, subject: @subject, kind: "Case")
    @entry.build_case_detail
    @card = @entry
  end

  # look up subject and build the 'template'
  def create
    @subject = current_user.subjects.find(card_params[:subject_id])
    @entry   = CardTemplate.new(card_params.merge(user: current_user, kind: "Case"))

    if @entry.save
      redirect_to entry_path(@entry), notice: "Saved", status: :see_other
    else
      @entry.build_case_detail unless @entry.case_detail
      @card = @entry
      render :new, status: :unprocessable_entity
    end
  end

  # ensure entry and card are aliases for views
  def show
    @entry = @card
  end

  # ensure entry and card are aliases for edit so form has fields
  def edit
    @entry = @card
    @entry.build_case_detail unless @entry.case_detail
  end

  # updates the template
  def update
    if @card.update(card_params)
      redirect_to entry_path(@card), notice: "Updated", status: :see_other
    else
      @card.build_case_detail unless @card.case_detail
      render :edit, status: :unprocessable_entity
    end
  end

  # delete the template
  def destroy
    subject_id = @card.subject_id
    @card.destroy!
    redirect_to entries_path(subject_id: subject_id), notice: "Deleted", status: :see_other
  end

  private
  #  find the card_template for the current user and hard guards to serve Case
  def set_card
    @card = CardTemplate.owned_by(current_user).includes(:subject, :case_detail).find(params[:id])
    redirect_to(entries_path, alert: "Unsupported type") and return unless @card.kind == "Case"
  end

  # support nesting attributes
  def card_params
    params.require(:card_template).permit(
      :subject_id,
      case_detail_attributes: [ :id, :case_name, :case_short_name, :full_citation, :material_facts, :issue, :key_principle ]
    )
  end
end
