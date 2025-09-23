class SessionsController < ApplicationController
  before_action :authenticate_user!
  # load the sessions belonging to the current user
  before_action :set_session, only: [ :show, :start, :pause, :resume, :reset, :advance, :destroy ]

  # give the user a list of most recent sessions - limit is arbitrary for web view
  def index
    @sessions = current_user.sessions.order(created_at: :desc).limit(20)
  end

  # display a form for the user to create a session (GET)
  def new
    @session  = current_user.sessions.new
    @subjects = current_user.subjects.order(:name)
  end

  # build a session (POST)
  def create
  # Load subjects
  @subjects = current_user.subjects.order(:name)

  # Read input from the user to create the session
  subject_id = params.dig(:session, :subject_id)
  name_param = params.dig(:session, :name).presence || "Session - #{Time.current.strftime('%-d %b %Y')}"
  count_param = params.dig(:session, :count).to_i

  # Validation that a subject has been selected
  unless subject_id.present?
      @session = current_user.sessions.new
      flash.now[:alert] = "Please choose a subject"
      return render :new, status: :unprocessable_entity
  end

  # Find the subject
  subject = current_user.subjects.find(subject_id)

  # Fetch the template
  templates = subject.card_templates
                     .owned_by(current_user)
                     .joins(:case_detail)  
                     .includes(:case_detail)
                     .ordered

  if templates.empty?
    @session = current_user.sessions.new
    flash.now[:alert] = "There are no cases for this subject"
    return render :new, status: :unprocessable_entity
  end

  bank = templates.to_a
  if count_param.positive?
  desired = [count_param, bank.size].min
  bank = bank.sample(desired)
  end

  # Create the session and build items / cards
  @session = current_user.sessions.new(subject: subject, name: name_param)
  @session.build_from_items!(items: bank, name: @session.name)  

  # Validate session created
  if @session.save
      redirect_to @session, notice: "Session created"
  else
      flash.now[:alert] = "Could not create session"
      render :new, status: :unprocessable_entity
  end
end

  # show a session
  def show
    @session.start! if @session.draft?
    @item = @session.prepare_current_item!
  end

  # mark a session in progress
  def start
    @session.start!
    redirect_to @session
  end

  # mark a session as paused
  def pause
    @session.pause!
    redirect_to @session
  end

  # mark a session as resumed / in progress
  def resume
    @session.resume!
    redirect_to @session
  end

  # reset a session
  def reset
    @session.reset!
    redirect_to sessions_path
  end

  # allow the user to mark a card as complete, and move to the next card
  def advance
    correct = ActiveModel::Type::Boolean.new.cast(params[:correct])
    @session.advance!(correct: correct)
    redirect_to @session
  end

  # delete the session and its items
  def destroy
    @session.destroy
    redirect_to sessions_path, notice: "Session deleted", status: :see_other
  end

  private

  def set_session
    @session = current_user.sessions.find(params[:id])
  end
end
