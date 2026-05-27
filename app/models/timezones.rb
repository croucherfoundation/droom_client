class Timezones

  FOLDER_PATH = Rails.root.join('public', 'timezone')

  class << self
    def find_by_key(key)
      data = JSON.parse(File.read("#{FOLDER_PATH}/timezones_selection_v2.json"))
      data.map{ |a| a.first }.find{ |v| v.include?(key) }
    end

    def for_selection
      JSON.parse(File.read("#{FOLDER_PATH}/timezones_selection_v2.json")).sort_by{|zone| zone.last}
    end

    def regenerate_json_file
      list = [["null", "Select timezone"]] # for null selection
      data = JSON.parse(File.read("#{FOLDER_PATH}/timezones.json"))

      data.each do |obj|
        value = obj['included'].join(',')

        label = obj['included'].map{|d|
          d = d.split('/')
          if d.length >= 2
            d.slice(1..).join('-').gsub("_", " ")
          else
            d.first.gsub("_", " ")
          end
        }.uniq.join(', ')

        list << [value, label]
      end

      File.write("#{FOLDER_PATH}/timezones_selection.json", JSON.dump(list))
      puts "✅ Re-arranged Timezones"
    end

    # Returns timezone options with GMT offset format: "Asia/Hong_Kong (GMT+8)"
    # Priority timezones appear at the top
    def for_selection_with_offset
      priority_keys = %w[
        Asia/Hong_Kong
        Asia/Singapore
        Asia/Shanghai
        Asia/Tokyo
        Europe/London
        America/New_York
        America/Los_Angeles
      ]

      all_zones = for_selection.map do |zone|
        key = zone.first
        if key == "null"
          [key, "Select timezone"]
        else
          # Get the first timezone identifier from the key (may contain comma-separated values)
          tz_identifier = key.split(',').first
          offset_label = format_gmt_offset(tz_identifier)
          label = "#{tz_identifier} (#{offset_label})"
          [key, label]
        end
      end

      # Separate null, priority and other timezones
      null_zone = []
      priority_zones = []
      other_zones = []

      all_zones.each do |zone|
        key = zone.first
        if key == "null"
          null_zone << zone
        else
          tz_identifier = key.split(',').first
          if priority_keys.include?(tz_identifier)
            priority_zones << zone
          else
            other_zones << zone
          end
        end
      end

      # Sort priority zones by their order in priority_keys
      priority_zones.sort_by! { |zone| priority_keys.index(zone.first.split(',').first) || 999 }

      # Combine: null first, then priority, then others
      null_zone + priority_zones + other_zones
    end

    def format_gmt_offset(tz_identifier)
      begin
        tz = ActiveSupport::TimeZone[tz_identifier] || TZInfo::Timezone.get(tz_identifier)
        if tz.is_a?(ActiveSupport::TimeZone)
          offset_seconds = tz.utc_offset
        else
          offset_seconds = tz.current_period.utc_total_offset
        end
        hours = offset_seconds / 3600
        minutes = (offset_seconds.abs % 3600) / 60
        if minutes > 0
          "GMT#{hours >= 0 ? '+' : ''}#{hours}:#{format('%02d', minutes)}"
        else
          "GMT#{hours >= 0 ? '+' : ''}#{hours}"
        end
      rescue
        "GMT"
      end
    end
  end
end
