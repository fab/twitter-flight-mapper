module AirportTimezones

  def list
    @timezone_hash ||= load_timezones
  end

  def load_timezones
    @timezone_hash = {}

    f = File.open('timezone_map.txt')
    f.each_line do |line|
      airport_code, timezone_name = line.strip.split(/\t/)
      @timezone_hash[airport_code] = timezone_name
    end

    @timezone_hash
  end
end
