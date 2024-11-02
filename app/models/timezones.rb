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
  end

end
