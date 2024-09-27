class BankAccountAccessLog
  include Her::JsonApi::Model

  use_api DROOM
  collection_path "/api/bank_account_access_logs"

  def self.new_with_defaults
    self.new({
      user_id: nil,
      user_name: "",
      person_uid: nil, 
      scholar_name: "", 
      log_type: "", 
      old_values: {}
    })
  end

end
