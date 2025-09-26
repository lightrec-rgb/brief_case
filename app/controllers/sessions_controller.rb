class SessionsController < ApplicationController
  before_action :authenticate_user!

  # Load the sessions belonging to the current user
  before_action :set_session, only: [ :show, :start, :pause, :resume, :reset, :advance, :destroy, :complete, :reopen ]

  # === Create ===
  # Build a blank unsaved session
  # Fetch all the user's subject (sorted alphabetically)
  # Prepare a hash to show counts next to each subject option, and count entries
  def new
    @session  = current_user.sessions.new
    @subjects = current_user.subjects.order(:name)

    @subject_card_counts = {}
    @subjects.each do |subj|
      subtree_ids = subj.subtree_ids

      base = CardTemplate
              .owned_by(current_user)
              .where(subject_id: subtree_ids)
              .left_joins(:case_detail, :provision_detail)

      both        = base.where("cases.id IS NOT NULL OR provisions.id IS NOT NULL").count
      only_cases  = base.where("cases.id IS NOT NULL").count
      only_provs  = base.where("provisions.id IS NOT NULL").count

      @subject_card_counts[subj.id] = {
        both: both,
        cases: only_cases,
        provisions: only_provs
      }
    end
  end

  # Read inputs from the user and validate
  # Build a pool from the subject tree and keep entries that have a case or provision
  # Build a session and items from the pool. Save or re-render on error
  def create
  @subjects = current_user.subjects.order(:name)

  subject_id = params.dig(:session, :subject_id)
  name_param = params.dig(:session, :name).presence || "Session - #{Time.current.strftime('%-d %b %Y')}"
  count_param = params.dig(:session, :count).to_i
  entry_scope = params.dig(:session, :entry_scope).presence || "both"

  unless subject_id.present?
      @session = current_user.sessions.new
      flash.now[:alert] = "Please choose a subject"
      return render :new, status: :unprocessable_entity
  end

  subject = current_user.subjects.find(subject_id)

  templates = CardTemplate
               .owned_by(current_user)
               .where(subject_id: subject.subtree_ids)
               .left_joins(:case_detail, :provision_detail)
               .includes(:case_detail, :provision_detail)
               .where("cases.id IS NOT NULL OR provisions.id IS NOT NULL")

  templates =
    case entry_scope
    when "cases"
      templates.where("cases.id IS NOT NULL")
    when "provisions"
      templates.where("provisions.id IS NOT NULL")
    else
      templates
    end

  if templates.empty?
    @session = current_user.sessions.new
    flash.now[:alert] = "There are no entries for this subject"
    return render :new, status: :unprocessable_entity
  end

  bank = templates.to_a
  if count_param.positive?
  desired = [ count_param, bank.size ].min
  bank = bank.sample(desired)
  end

  @session = current_user.sessions.new(subject: subject, name: name_param)
  @session.build_from_items!(items: bank, name: @session.name)

  if @session.save
      redirect_to sessions_path, notice: "Session created", status: :see_other
  else
      flash.now[:alert] = "Could not create session"
      render :new, status: :unprocessable_entity
  end
end

  # === Read ===
  # Show two lists - active (not completed), and archived (completed)
  def index
    @active_sessions   = current_user.sessions.where.not(status: :completed).order(created_at: :desc).limit(20)
    @archived_sessions = current_user.sessions.where(status: :completed).order(updated_at: :desc).limit(20)
  end

  # Ask the session for the item to study next
  # Grab display options from the item and render the item
  def show
    @item = @session.prepare_current_item!
    @options = @item&.preview_options || {}
  end

  # === Update ===
  # Mark session complete and redirect to sessions index
  def complete
    @session.complete!
    redirect_to sessions_path, notice: "Session marked as completed", status: :see_other
  end

  # Mark session started and redirect to its show page (pre FSRS)
  def start
    @session.start!
    redirect_to @session
  end

  # Mark session paused and redirect to its show page (pre FSRS)
  def pause
    @session.pause!
    redirect_to @session
  end

  # Mark session resumed and redirect to its show page (pre FSRS)
  def resume
    @session.resume!
    redirect_to @session
  end

  # Reset session status and redirect to sessions index
  def reset
    @session.reset!
    redirect_to sessions_path
  end

  # Reopen a completed or paused session by updating fields and redirect to sessions index
  def reopen
    @session.reopen!
    redirect_to sessions_path, notice: "Session reopened"
  end

  # Read a 1-4 rating (default 3)
  # Call advance_with_rating! to record and schedule next item, redirect to show
  def advance
    rating = params[:rating].to_i
    rating = 3 unless (1..4).include?(rating) # default to GOOD
    @session.advance_with_rating!(rating)
    redirect_to @session
  end

  # === Destroy ===
  # Delete the session and its items
  def destroy
    @session.destroy
    redirect_to sessions_path, notice: "Session deleted", status: :see_other
  end

  private

  # Find a session by ID for the current user
  def set_session
    @session = current_user.sessions.find(params[:id])
  end
end
