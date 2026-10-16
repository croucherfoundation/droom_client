require 'her'

module DroomClient
  module Middleware
    # Parses API responses that wrap the record in a named envelope, e.g.
    #
    #   {
    #     "success": true,
    #     "message": "參加者已成功創建。",
    #     "attendee": { "id": 123, "name": "Jane Smith" }
    #   }
    #
    # Her expects the parsed body to be a hash of the shape
    # { data:, errors:, metadata: }. This middleware lifts the record out of
    # the envelope into :data and keeps success/message in :metadata.
    #
    # Bodies that are already JSON:API / Her-shaped (top-level "data") are
    # normalised and passed through, so existing endpoints keep working.
    class EnvelopeParser < Her::Middleware::ParseJSON
      # Keys that are envelope metadata rather than the record itself.
      META_KEYS = %w[success message errors metadata meta].freeze

      def on_complete(env)
        env[:body] = case env[:status]
                     when 204, 304
                       empty_response
                     else
                       parse_envelope(env[:body])
                     end
      end

      private

      def parse_envelope(body)
        json = parse_json(body)
        return empty_response unless json.is_a?(Hash)

        # Already Her-shaped — just normalise errors/metadata.
        return her_shaped(json) if json.key?(:data)

        key = record_key(json)
        errors = json[:errors] || (json[:success] == false ? Array(json[:message]) : [])

        {
          data: (key ? json[key] : {}) || {},
          errors: errors,
          metadata: json.reject { |k, _| k == key }
        }
      end

      def her_shaped(json)
        {
          data: json[:data] || {},
          errors: json[:errors] || [],
          metadata: json[:metadata] || json[:meta] || {}
        }
      end

      # The first non-meta key holding the record (e.g. :attendee, :event).
      def record_key(json)
        json.keys.find { |k| !META_KEYS.include?(k.to_s) }
      end

      def empty_response
        { data: {}, errors: [], metadata: {} }
      end
    end
  end
end
