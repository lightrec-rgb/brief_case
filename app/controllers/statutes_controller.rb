class StatutesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_act
  before_action :set_statute, only: [:edit, :update]

  def new
    # Build an entry (CardTemplate)  statute detail prefilled from the Act header
    @entry = current_user.card_templates.new(subject: @act.subject, kind: "Statute")
    @entry.build_statute_detail(
      act: @act,
      act_name: @act.act_name,
      act_short_name: @act.act_short_name,
      jurisdiction: @act.jurisdiction,
      year: @act.year
    )
  end

  def create
    # 1) Create a blank template for this subject/kind
    @entry = current_user.card_templates.new(subject: @act.subject, kind: "Statute")

    # 2) Ensure the child exists to receive attrs
    @entry.build_statute_detail unless @entry.statute_detail

    # 3) Assign incoming params to parent + nested (requires accepts_nested_attributes_for)
    @entry.assign_attributes(entry_params)

    # 3b) Extra safety: assign nested directly to child too (harmless if already set)
    if (sd = entry_params[:statute_detail_attributes]).present?
      @entry.statute_detail.assign_attributes(sd)
    end

    # 4) Link the Act so Statute validations pass and your before_validation can copy headers
    @entry.statute_detail.act = @act

    if @entry.save
      redirect_to entries_path(subject_id: @act.subject_id, anchor: "act-#{@act.id}"),
                  notice: "Provision added."
    else
      # You’ll see errors on the form if anything failed validation
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @statute = @act.statutes.find(params[:id])   # or set_statute before_action
    @entry   = @statute.card_template
    @entry.build_statute_detail unless @entry.statute_detail
  end

  def update
    @statute = @act.statutes.find(params[:id])   # or set_statute before_action
    @entry   = @statute.card_template

    if @entry.update(entry_params)
      redirect_to entries_path(subject_id: @act.subject_id, anchor: "act-#{@act.id}"),
                  notice: "Provision updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_act
    @act = current_user.acts.find(params[:act_id])
  end

  def set_statute
    @statute = @act.statutes.find(params[:id])
  end

  def entry_params
    params.require(:card_template).permit(
      :name,
      statute_detail_attributes: [:provision_ref, :provision_text]
    )
  end
end