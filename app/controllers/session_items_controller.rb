class SessionItemsController < ApplicationController
  before_action :authenticate_user!

  # Find the session item about to be used
  before_action :set_item

  # Historical method pre FSRS to mark session item as seen
  def seen
    @item.mark_seen!
    redirect_back fallback_location: session_path(@item.session)
  end

  # Historical method pre FSRS to mark session item as done / complete
  def done
    correct = case params[:correct]
    when "true"  then true
    when "false" then false
    else nil
    end
    @item.mark_done!(correct: correct)
    redirect_back fallback_location: session_path(@item.session)
  end

  private

  # Allow for fitering by session by user
  def set_item
    @item = SessionItem
           .joins(:session)
           .includes(:session)
           .where(sessions: { user_id: current_user.id })
           .find(params[:id])
  end
end
