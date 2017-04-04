module IndexUser
  extend ActiveSupport::Concern

  def reindex_user(user_uid)    
    User.reindex_user(user_uid)
  end

end
