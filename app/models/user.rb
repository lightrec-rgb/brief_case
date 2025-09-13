class User < ApplicationRecord
# Include default devise modules. Others available are:
# Include default devise modules. Others available are:
# :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
devise :database_authenticatable, :registerable,
       :recoverable, :rememberable, :validatable,
       :omniauthable, omniauth_providers: %i[google_oauth2]

def self.from_omniauth(auth)
  # Try to find user by provider and uid first
  user = where(provider: auth.provider, uid: auth.uid).first

  # If not found, try to find by email
  user ||= find_by(email: auth.info.email)

  # If user found by email but no provider/uid, update them
  if user
    user.update(provider: auth.provider, uid: auth.uid) if user.provider.nil? || user.uid.nil?
    return user
  end

  # Otherwise, create new user
  create do |user|
    user.email = auth.info.email
    user.password = Devise.friendly_token[0, 20]
    user.avatar_url = auth.info.image
    user.name = auth.info.name
    user.provider = auth.provider
    user.uid = auth.uid
  end
end
end
