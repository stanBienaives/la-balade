require 'pry'
require 'json'
require 'date'

class Extractor


  @@types_whitelist = ['JPG','MOV','mp4']
  
  def extract( directories )
    directories = [directories] unless directories.is_a? Array
    extraction = raw_extract( directories )
    @positions = extraction.map do |extract|
        apply_label extract rescue nil
    end

    @positions.reject!(&:nil?)
    
  end

  def extract_and_save(directories, path)
    @position ||= extract(directories)
    File.open( path, 'w') do |f|
      f.write( @positions.to_json )
    end
  end


  private


  # simple wrapper for exiftool command line tool
  def raw_extract( directories , types_whitelist = @@types_whitelist)
    json = []
    directories.each do |dir|
      types_whitelist.each do |type|
        p cmd = "exiftool -j -ext #{type} #{dir}"
        json += JSON.parse(%x(#{cmd})) rescue next
      end
    end
    json
  end

  def apply_label( raw_extract )
    {
      position: coordinate_decimal( raw_extract["GPSPosition"]),
      created_at: convert_proper_date_format( raw_extract["CreateDate"] ),
      name: raw_extract['FileName'],
      path: raw_extract["Directory"] + '/' + raw_extract['FileName'],
      type: raw_extract['FileType'],
      id: raw_extract['FileName'], # identifier will be the filename
      description: description_from_coordinates( coordinate_decimal( raw_extract["GPSPosition"]) ),
      altitude: raw_extract['GPSAltitude']
    }
  end


  # Transform coordinate into decimal
  def coordinate_decimal( raw_data )
    #format "24 deg 47' 24.99\" S, 65 deg 24' 14.95\" W"
    return nil if raw_data.nil?
    longitude = raw_data.split(', ')[1]
    latitude = raw_data.split(', ')[0]
    latitude  =  latitude.match /([0-9]{1,3}) deg ([0-9]{1,3})' ([0-9]{1,2}.[0-9]{1,2})\" ([S,N,W,E])/
    longitude =  longitude.match /([0-9]{1,3}) deg ([0-9]{1,3})' ([0-9]{1,2}.[0-9]{1,2})\" ([S,N,W,E])/
    {
      latitude: convert_polar_to_sign(  latitude[4]  ) * convert_sexadecimal( latitude[1], latitude[2] , latitude[3]),
      longitude: convert_polar_to_sign( longitude[4]) * convert_sexadecimal( longitude[1], longitude[2] , longitude[3])
    }
  end

  def convert_sexadecimal( degres, seconds, cents )
    degres.to_f + seconds.to_f / 60 + cents.to_f / 1000000
  end

  def convert_polar_to_sign( polar )
    return -1 if polar == 'S' || polar == 'W'
    return 1 if polar == 'N' || polar == 'E'
  end

  def convert_proper_date_format( raw_format )
    #2015:01:15 20:44:20 => 2015/01/15 20:44:20
    date = raw_format.split(' ')[0]
    time = raw_format.split(' ')[1]
    DateTime.parse "#{ date.gsub(':','/') } #{time}"
  end

  # fetch place description based on position
  def description_from_coordinates( p )
    return "" unless @set_description
    return "" if p.nil?
    Timeout.timeout(2) do
      address = Geocoder.address([p[:latitude], p[:longitude]])
      p address
      return address
    end
  rescue => e
    p 'geocoding timeout'
    return ""
  end

end

