require 'json'
require 'date'
require 'geocoder'
require 'pry'


# Etract exif properties of files in a given directory
class GPSExtractor

  def initialize( options= {} )
    options[:directory] = options[:directories] if options[:directories]
    options[:directory] = [options[:directory]] if options[:directory].is_a? String
    raise ArgumentError, 'you should give at least a directory of a tag' if options[:directory].nil? && options[:filter_by_tag].nil?
    @directory = options[:directory]
    @type_of_file = options[:type_of_file] || ['JPG','MOV','mp4']
    @set_description = options[:set_description] || false
    @print_stats = options[:print_stats] || false

    # options to filter by tag (only OSX )
    # !! Caution in this case the given directory is not used files will be searched in all the computer
    @filter_by_tag = options[:filter_by_tag] || false
    @current_directory = %x(pwd)
  end

  def extract_all_postions
    interpolations
    stats if @print_stats
    filter_by_tag if @filter_by_tag
    numbering
    cleaning
    return data_extraction
  end


private

  # simple wrapper for exiftool command line tool
  def extract
    json = []
    @directory.map do |dir|
       cmd = "exiftool -j #{@type_of_file.map{ |type| dir + "/*" + type }.join(' ')}"
       json += JSON.parse(%x(#{cmd}))
    end
    json
  end


  # make interpolation for image not geotagged
  def interpolations
    data_extraction.sort_by! { |d| d[:created_at] } # redondant...
    data_extraction.each_with_index do |p,i|
      if p[:position].nil?
        # find next available position for interpolation
        begin
          increment = 1
          increment +=1 while data_extraction[i+increment][:position].nil?
          p[:position]  = interpolation( p[:created_at] , data_extraction[i-1], data_extraction[i+increment] )
        rescue => e
          p "Unable to interpolate position"
          p[:position] = nil
        end
      end
    end
  end

  # guess position based on timestamps
  def interpolation( timestamp , previous, nextp )
    return nil if previous[:position].nil? || nextp[:position].nil?
    # convert to unix timestamps for calculation
    t1 = previous[:created_at].to_time.to_i.to_f
    t2 = nextp[:created_at].to_time.to_i.to_f
    t = timestamp.to_time.to_i.to_f
    position = {}

    ratio = (t - t1) / ( t2 - t1 )

    %i(latitude longitude).each do |card|
      # ratio = (position[card] - previous[:position][card] ) / (nextp[:position][card] - previous[:position][card] )
      position[card] = (nextp[:position][card] - previous[:position][card]) * ratio + previous[:position][card]

    end
    position
  end

  # set index on each position
  def numbering
    index = 0;
    data_extraction.sort_by! { |d| [:created_at] }
                   .each { |d| index = index+1 ; d[:index] = index }
  end

  # remove photos with no positions
  def cleaning
    data_extraction.reject! { |d| d[:position].nil? }
  end

  def stats
    puts "Total files:            #{data_extraction.count}"
    puts "Total with no GPSdata:  #{data_extraction.count { |d| d[:position].nil?   } }"
    puts "videos with no GPSdata: #{data_extraction.count { |d| d[:position].nil? && d[:type] == 'MOV' } }"
  end


  def filter_by_tag
    paths = %x(mdfind 'kMDItemUserTags == #{@filter_by_tag}').split(/\n/)
    data_extraction.keep_if { |d| paths.include?(d[:path]) }
  end


  # extract meaningful information from raw exiftool output
  def data_extraction
    return @data_extraction if @data_extraction
    #json = JSON.parse(%x(#{cmd}))
    json = extract
    @data_extraction = json.map do |j|
      p j if j['CreateDate'].nil?
      {
        position: coordinate_decimal( j["GPSPosition"]),
        created_at: convert_proper_date_format( j["CreateDate"] ),
        name: j['FileName'],
        path: j["Directory"] + '/' + j['FileName'],
        type: j['FileType'],
        id: j['FileName'], # identifier will be the filename
        description: description_from_coordinates( coordinate_decimal( j["GPSPosition"]) ),
        altitude: j['GPSAltitude']
      }
    end
  end


  # Transform coordinate into decimal
  def coordinate_decimal( raw_data )
    #format "24 deg 47' 24.99\" S, 65 deg 24' 14.95\" W"
    return nil if raw_data.nil?
    longitude = raw_data.split(', ')[1]
    latitude = raw_data.split(', ')[0]
    latitude  =  latitude.match /([0-9]{1,2}) deg ([0-9]{1,2})' ([0-9]{1,2}.[0-9]{1,2})\" ([S,N,W,E])/
    longitude =  longitude.match /([0-9]{1,2}) deg ([0-9]{1,2})' ([0-9]{1,2}.[0-9]{1,2})\" ([S,N,W,E])/
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


# Convert array of positions into a proper Geojson file and save it
class GeoJsonBuilder

  def convert_to_line_string( positions, properties = {} )
    @geojson  = feature( properties ) do
      lineString do
        positions.map{ |coordinates| position_to_array( coordinates ) }
      end
    end
    self
  end

  def convert_to_points( positions , properties = {})
    @geojson = feature_collection do
      positions.map do |p|
        feature( p.merge( properties) ) do
          point do
            position_to_array( p )
          end
        end
      end
    end
    self
  end

  def save(path)
    File.open( path, 'w') do |f|
      f.write( @geojson.to_json )
    end
  end

  private


  def position_to_array( position )
    [position[:position][:longitude],position[:position][:latitude]]
  end


  def point
    {
      type: "Point",
      coordinates: yield
    }
  end


  def lineString
    {
      type: "LineString",
      coordinates: yield,
    }
  end

  def feature( options = {} )
    properties = default_properties.merge( options )
    {
      type: "Feature",
      geometry: yield,
      properties: properties
    }
  end

  def feature_collection( options = {} )
    {
      type: "FeatureCollection",
      id: options[:id],
      features: yield
    }
  end


  def default_properties
    {
        stroke:      "#f86767",
        title:       "Trajectory",
        description: 'The road'
    }
  end



end



# search in directory
positions = GPSExtractor.new( directories: ["/Users/sebastienvian/Desktop/photos-iphone-am",
                                            "/Users/sebastienvian/Desktop/photos-iphone-as"
                                            "/Users/sebastienvian/Desktop/LA\ BALLADE/**/"
                                            ],
                              filter_by_tag: 'Violet',
                              set_description: false,
                              print_stats: false
).extract_all_postions

# for search by tag
#positions = GPSExtractor.new("dummydirectory", set_description: false, print_stats: false, filter_by_tag: 'Violet' ).extract_all_postions

#positions = GPSExtractor.new(".", set_description: false, print_stats: true, type_of_file: ['.MOV'] ).extract_all_postions
images = positions.select { |p| true  }
videos = positions.select { |p| p[:type] == 'MOV' }

# save videos
GeoJsonBuilder.new.convert_to_points( videos ,
  { "marker-color" => "#f86767", "marker-symbol" => "cinema", "marker-size" => "medium"} ).save('./front/videos.json')

# save all points
#GeoJsonBuilder.new.convert_to_line_string( images ).save('./images.json')
