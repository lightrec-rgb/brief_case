class ActsController < ApplicationController
  before_action :authenticate_user!

  # Load the Act for the current user for these actions
  before_action :set_act, only: [ :show, :edit, :update, :destroy ]

  # === Create ===
  # If passed, look up subject so it can be preselected
  # Build a new Act for current user with subject prefilled in the form
  def new
    @subject = current_user.subjects.find_by(id: params[:subject_id])
    @act = current_user.acts.new(subject: @subject)
  end

  # Build a new act for current user from strong parameters
  # Return to entries page or error
  def create
    @act = current_user.acts.new(act_params)
    if @act.save
      redirect_to entries_path(subject_id: @act.subject_id, anchor: "act-#{@act.id}"),
                  notice: "Act created"
    else
      @subject = @act.subject
      render :new, status: :unprocessable_entity
    end
  end

  # === Read ===
  # Load the Act's provisions with associated card_template, order by provision reference
  def show
    @provisions = @act.provisions.joins(:card_template)
                      .includes(:card_template)
                      .order(Arel.sql("LOWER(COALESCE(provision_ref,''))"))
  end

  # === Update ===
  # Render the edit form
  def edit; end

  # Try to update the Act and return to entries page, or error
  def update
    if @act.update(act_params)
      redirect_to entries_path(subject_id: @act.subject_id, anchor: "act-#{@act.id}"),
                  notice: "Act updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # === Destroy ===
  # Delete the Act and redirect back to subject list
  # Will not delete if Act has provisions
  def destroy
    subject_id = @act.subject_id
    if @act.destroy
      redirect_to entries_path(subject_id: subject_id),
                  status: :see_other,
                  notice: "Act deleted"
    else
      redirect_to entries_path(subject_id: subject_id, anchor: "act-#{@act.id}"),
                  alert: "You must delete this Act’s provisions before deleting the Act"
    end
  end

  private

  # Find the Act by ID, preload subject and scope to the current user
  def set_act
    @act = current_user.acts.includes(:subject).find(params[:id])
  end

  # Strong paramaters - only allow these Act attributes from the form
  def act_params
    params.require(:act).permit(:subject_id, :act_name, :act_short_name, :jurisdiction, :year)
  end
end
