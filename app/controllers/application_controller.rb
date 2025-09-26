class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
   protect_from_forgery with: :null_session

  # Remember the last subject accessed
  def remember_subject!(subject)
    session[:last_subject_id] = subject.id if subject
  end

  def last_subject_for(user)
    user.subjects.find_by(id: session[:last_subject_id])
  end
end
