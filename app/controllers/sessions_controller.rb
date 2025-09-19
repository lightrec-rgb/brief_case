class SessionsController < ApplicationController
  before_action :authenticate_user!
  # load the sessions belonging to the current user
  before_action :set_session, only: [:show, :start, :pause, :resume, :reset, :advance, :destroy]

  # give the user a list of most recent sessions - limit is arbitrary for web view
  def index
    @sessions = current_user.sessions.order(created_at: :desc).limit(20)
  end

  # display a form for the user to create a session (GET)
  def new
    @subjects = current_user.subjects.order(:name)
  end

  # build a session (POST)
  def create
    subject = current_user.subjects.find(params[:subject_id])

    # only templates that actually have a case
    templates = subject.card_templates
                       .owned_by(current_user)
                       .joins(:case_detail)
                       .includes(:case_detail)

    existing_cards = Card.where(user: current_user, subject: subject).pluck(:card_template_id)
    (templates.map(&:id) - existing_cards).each do |template_id|
      t = CardTemplate.find(template_id)
      Card.create!(user: current_user, subject: subject, card_template: t, kind: t.kind)
    end

    items = Card.where(user: current_user, subject: subject)
                .joins(card_template: :case_detail)

    ensure_global_case_card!
    
    if items.blank?
      @subjects = current_user.subjects.order(:name)
      flash.now[:alert] = "There are no cases for this subject."
      return render :new, status: :unprocessable_entity
    end

    @session = current_user.sessions.new(subject: subject, name: params[:name].presence)
    @session.build_from_items!(items: items.to_a, name: @session.name)

    if @session.save
      redirect_to @session, notice: "Session created"
    else
      @subjects = current_user.subjects.order(:name)
      flash.now[:alert] = "Could not create session"
      render :new, status: :unprocessable_entity
    end
  rescue ArgumentError => e
    # Handles "There are no cases for this subject" from build_from_items!
    @subjects = current_user.subjects.order(:name)
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end
  
  # show a session
  def show
    @current_item = @session.current_item
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
    redirect_to @session
  end

  # allow the user to mark a card as complete, and move to the next card
  def advance
    correct = case params[:correct]
              when "true"  then true
              when "false" then false
              else nil
              end
    @session.advance!(correct: correct)
    redirect_to @session
  end

  # delete the session and its items
  def destroy
    @session.destroy
    redirect_to sessions_path, notice: "session deleted"
  end

  private

  def set_session
    @session = current_user.sessions.find(params[:id])
  end

  def ensure_global_case_card!
    return if CaseCard.exists?

    # pick any holder Card of kind "Case" (create one if none yet)
    holder_card = Card.where(kind: "Case").first   # no need to joins(:card_template)
  unless holder_card
    t = CardTemplate.joins(:case_detail).first
    raise "No Case templates exist to create global CaseCard" unless t
    holder_card = Card.create!(user: t.user, subject: t.subject, card_template: t, kind: t.kind, name: t.name)
  end

  placeholder_case = Case.first || holder_card.card_template.case_detail
  raise "No Case record found to attach to global CaseCard" unless placeholder_case

  CaseCard.create!(card: holder_card, case: placeholder_case)
  end
end