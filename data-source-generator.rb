require 'json'
require 'date'
require 'geocoder'
require 'pry'


# Etract exif properties of files in a given directory
#
#
class GPSExtractor

  def initialize( options= {} )
    options[:directory] = options[:directories] if options[:directories]
    options[:directory] = [options[:directory]] if options[:directory].is_a? String
    raise ArgumentError, 'you should give at least a directory of a tag' if options[:directory].nil? && options[:filter_by_tag].nil?
    @directory = options[:directory]
    @type_of_file = options[:type_of_file] || ['JPG','MOV','mp4']

  end

  def save( file )
    File.open( file, 'w' ) do |f|
      f.write extract_all_postions.to_json
    end
  end


private



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
positions = GPSExtractor.new( directories: ['/Users/sebastienvian/Desktop/selection-videos',
                                            '/Users/sebastienvian/Desktop/photos-iphone-as',
                                            '/Users/sebastienvian/Desktop/photos-iphone-as-2',
                                            '/Users/sebastienvian/Desktop/photos-iphone-am',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150101\ PARIS',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150107\ BUENOS\ AIRES',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150110\ SAN\ IGNACIO',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150112\ IGUAZU',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150115\ SALTA',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150116\ EL\ CARMEN',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150118\ PURMAMARCA',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150119\ TILCARA',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150120\ PUMA\ MAKA',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150121\ AUTREPART',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150122\ EL\ QUIACA',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150123\ VILLAZON',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150124\ TUPIZA',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150126\ SUD\ JUJU',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150126\ SUD\ LIPEZ',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150204\ POTOSI',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150206\ SUCRE',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150212\ ORURO',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150214\ LA\ PAZ',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150219\ HUYANA\ POTOSI',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150224\ COPACABANA',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150225\ ISLA\ DEL\ SOL',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150228\ PUNO\ ISLA\ UROS',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150304\ AGUAS\ CALIENTES',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150306\ CUZCO',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150308\ TREK\ SALKANTAY\ +\ MACHU\ PICHU',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150315\ LIMA',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150318\ SANTIAGO_VALPARAISO',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150324\ SYDNEY',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150327\ JERVIS\&CO',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/150401\ PHILIPPINES',
                                            '/Users/sebastienvian/Desktop/LA\ BALADE/Philippines\ 2'

                                            ],
                              filter_by_tag: 'Violet',
                              set_description: false,
                              print_stats: false
).extract_all_postions

# for search by tag
#positions = GPSExtractor.new("dummydirectory", set_description: false, print_stats: false, filter_by_tag: 'Violet' ).extract_all_postions

#positions = GPSExtractor.new(".", set_description: false, print_stats: true, type_of_file: ['.MOV'] ).extract_all_postions
images = positions.select { |p| true  }
videos = positions.select { |p| ['MOV','MP4'].include? p[:type]  }

# save videos
GeoJsonBuilder.new.convert_to_points( videos ,
  { "marker-color" => "#f86767", "marker-symbol" => "cinema", "marker-size" => "medium"} ).save('./front/videos.json')

# save all points
#GeoJsonBuilder.new.convert_to_line_string( images ).save('./images.json')
