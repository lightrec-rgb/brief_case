class ActsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_act, only: [:show, :edit, :update]

  def index
    redirect_to entries_path and return
  end

  def new
    @subject = current_user.subjects.find_by(id: params[:subject_id])
    @act = current_user.acts.new(subject: @subject)
  end

  def create
    @act = current_user.acts.new(act_params)
    if @act.save
      redirect_to act_path(@act), notice: "Act created"
    else
      @subject = @act.subject
      render :new, status: :unprocessable_entity
    end
  end

  def show
    redirect_to entries_path(subject_id: @act.subject_id, anchor: "act-#{@act.id}")
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

  private

  def set_act
    @act = current_user.acts.includes(:subject).find(params[:id])
  end

  def act_params
    params.require(:act).permit(:subject_id, :act_name, :act_short_name, :jurisdiction, :year)
  end
end
