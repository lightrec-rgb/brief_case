class ActsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_act, only: [ :show, :edit, :update, :destroy ]

  def new
    # Preselect the subject from the Entries page link: new_act_path(subject_id: @subject.id)
    @subject = current_user.subjects.find_by(id: params[:subject_id])
    @act = current_user.acts.new(subject: @subject)
  end

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

  def show
    @provisions = @act.provisions.joins(:card_template)
                      .includes(:card_template)
                      .order(Arel.sql("LOWER(COALESCE(provision_ref,''))"))
  end

  def edit; end

  def update
    if @act.update(act_params)
      redirect_to entries_path(subject_id: @act.subject_id, anchor: "act-#{@act.id}"),
                  notice: "Act updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    subject_id = @act.subject_id
    if @act.destroy
      redirect_to entries_path(subject_id: subject_id),
                  status: :see_other,
                  notice: "Act deleted"
    else
      # Act has provisions; show a friendly message and keep them on Entries
      redirect_to entries_path(subject_id: subject_id, anchor: "act-#{@act.id}"),
                  alert: "You must delete this Act’s provisions before deleting the Act"
    end
  end

  private
  def set_act
    @act = current_user.acts.includes(:subject).find(params[:id])
  end

  def act_params
    params.require(:act).permit(:subject_id, :act_name, :act_short_name, :jurisdiction, :year)
  end
end
