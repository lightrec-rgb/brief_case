class CardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_card, only: [ :show, :destroy ]

  # show a single card for testing
  def show
    @case_card = @card.case_card
  end

  # create a card shell with properties for session to inherit
  def create
    template = current_user.card_templates.find(card_create_params[:card_template_id])

    @card = Card.new(
      card_template: template,
      user:          current_user,
      subject:       template.subject,
      kind:          template.kind,
    )

    # save the new card shell
    if @card.save
      redirect_to template
    else
      render :new, status: :unprocessable_entity
    end
  end

  # delete a card shell, including its casecard
  def destroy
    entry = @card.card_template
    @card.destroy
    redirect_to entry
  end

  private

  # load a card by ID for the current user
  def set_card
    @card = current_user.cards.find(params[:id])
  end

  #  ensure card_template_id can be accessed
  def card_create_params
    params.require(:card).permit(:card_template_id)
  end
end
