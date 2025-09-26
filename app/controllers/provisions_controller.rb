class ProvisionsController < ApplicationController
  before_action :authenticate_user!

  # Load the parent Act of a provision first
  before_action :set_act

  # Load the provision for the current user for these actions for the Act
  before_action :set_provision, only: [ :edit, :update, :destroy ]

  # === Create ===
  # Build a new card_template of kind provision to th same subject as the Act
  # Prebuild the provision detail object so the form has fields, seeded with the Act's info
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

  # Build a new card_template of kind provision to th same subject as the Act
  # Assign attributes to the card_template
  # Save the provision and redirect to entries page or provide an error
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

  # === Read ===
  # Placeholder show action
  def show; end

  # === Update ===
  # The entry is the template that owns the provision
  def edit
    @entry = @provision.card_template
    @entry.build_provision_detail unless @entry.provision_detail
  end

  # Update card_template / provision detail, return to entries page or provide an error
  def update
    @entry = @provision.card_template
    if @entry.update(entry_params)
      redirect_to entries_path(subject_id: @act.subject_id, anchor: "act-#{@act.id}"),
                  notice: "Provision updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # === Destroy ===
  # Deletes the provision and redirect back to subject list
  def destroy
    if @provision
      @provision.destroy
      redirect_to entries_path(subject_id: @act.subject_id, anchor: "act-#{@act.id}"),
                status: :see_other,
                notice: "Provision deleted"
    end
  end

  private

  # Load the parent Act by ID for the current user
  def set_act
    @act = current_user.acts.find(params[:act_id])
  end

  # Find the provision by ID for the current user. If not found go back to entries with error
  # Ensure the provision actually belongs to the loaded Act
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

  # Ensure only provision fields can be assigned
  def entry_params
    params.require(:card_template).permit(
      :name,
      provision_detail_attributes: [ :id, :provision_ref, :provision_text ]
    )
  end
end
