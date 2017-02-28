module IndexUser
  extend ActiveSupport::Concern

  def reindex_user
    User.reindex_user
  end

end
