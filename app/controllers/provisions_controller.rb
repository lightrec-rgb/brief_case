class ProvisionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_act
  before_action :set_provision, only: [ :edit, :update, :destroy ]

  def new
    @entry = current_user.card_templates.new(subject: @act.subject, kind: "Provision")
    @entry.build_provision_detail(
      act: @act,
      act_name: @act.act_name,
      act_short_name: @act.act_short_name,
      jurisdiction: @act.jurisdiction,
      year: @act.year
    )
  end

  def create
    @entry = current_user.card_templates.new(subject: @act.subject, kind: "Provision")
    @entry.build_provision_detail unless @entry.provision_detail
    @entry.assign_attributes(entry_params)

    if (pd = entry_params[:provision_detail_attributes]).present?
      @entry.provision_detail.assign_attributes(pd)
    end

    @entry.provision_detail.act = @act

    if @entry.save
      redirect_to entries_path(subject_id: @act.subject_id, anchor: "act-#{@act.id}"),
                  notice: "Provision added"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @entry = @provision.card_template
    @entry.build_provision_detail unless @entry.provision_detail
  end

  def update
    @entry = @provision.card_template
    if @entry.update(entry_params)
      redirect_to entries_path(subject_id: @act.subject_id, anchor: "act-#{@act.id}"),
                  notice: "Provision updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @provision
      @provision.destroy
      redirect_to entries_path(subject_id: @act.subject_id, anchor: "act-#{@act.id}"),
                status: :see_other,
                notice: "Provision deleted"
    end
  end

  private

  def set_act
    @act = current_user.acts.find(params[:act_id])
  end

  def set_provision
    @provision = Provision.find_by(id: params[:id])

    if @provision.nil?
      redirect_back fallback_location: entries_path(subject_id: @act.subject_id, anchor: "act-#{@act.id}"),
                    alert: "Provision not found"
      return
    end

    if @provision.act_id != @act.id
      redirect_back fallback_location: entries_path(subject_id: @act.subject_id, anchor: "act-#{@act.id}"),
                    alert: "This provision belongs to a different Act"
    end
  end

  def entry_params
    params.require(:card_template).permit(
      :name,
      provision_detail_attributes: [ :id, :provision_ref, :provision_text ]
    )
  end
end
