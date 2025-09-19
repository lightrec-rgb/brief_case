class SessionItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_item

  def seen
    @item.mark_seen!
    redirect_back fallback_location: session_path(@item.session)
  end

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

  def set_item
    @item = SessionItem.joins(:session).where(sessions: { user_id: current_user.id }).find(params[:id])
  end
end
