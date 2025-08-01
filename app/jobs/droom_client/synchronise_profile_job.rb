require 'open-uri'
module DroomClient
  class SynchroniseProfileJob < ActiveJob::Base
    queue_as :default
    retry_on OpenURI::HTTPError, wait: 10.seconds, attempts: 3

    discard_on ActiveRecord::RecordNotFound
    def perform(record, record_type)
      if record.send(record_type).attached?
        URI.open(record.send(record_type).url)
        User.sync_profile_image(record.user_uid, {image_url:  record.send(record_type).url})
      end
    end
  end
end
