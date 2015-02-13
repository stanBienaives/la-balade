require 'json'
require 'date'


class GPSExtractor

  def initialize( directory = '.' )
    @directory = directory
  end

  def extract_all_postions
    data_extraction.sort_by{ |d| d[:created_at] }
                   .reject!{ |d| d[:position].nil? }
  end


private

  def cmd
   #"exiftool -j #{@directory}/*.MOV #{@directory}/*.jpg"
   "exiftool -j #{@directory}/*.MOV"
  end


  def data_extraction
    json = JSON.parse(%x(#{cmd}))
    json.map do |j|
      {
        position: coordinate_decimal( j["GPSPosition"]),
        created_at: convert_proper_date_format( j["CreateDate"] )
      }
    end
  end

  def coordinate_decimal( raw_data )
    #format "24 deg 47' 24.99\" S, 65 deg 24' 14.95\" W"
    return nil if raw_data.nil?
    longitude = raw_data.split(', ')[0]
    latitude = raw_data.split(', ')[1]
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

end


class GeoJsonBuilder

  def convert_to_line_string( positions )
    @geojson  = feature( id: 'myid', stroke: '#999' , title: 'hello ma biche' ) do
      lineString do
        positions.map{ |coordinates| position_to_array( coordinates ) }
      end
    end
    self
  end

  def convert_to_points( positions )
    @geojson = feature_collection( id: 'allid', title: 'videos' ) do
      positions.map do |p|
        feature( :description => 'point', :stroke => '#eee' , :id => "#{(rand* 1000).to_i.to_s}") do
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
    [position[:position][:latitude], position[:position][:longitude] ]
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
    {
      type: "Feature",
      geometry: yield,
      properties: {
        id:          options[:id]          || "description",
        stroke:      options[:stroke]      || "#f86767",
        title:       options[:title]       || "Trajectory",
        description: options[:description] || 'The road'
      }
    }
  end

  def feature_collection( options = {} )
    {
      type: "FeatureCollection",
      id: options[:id],
      features: yield
    }
  end



end



positions = GPSExtractor.new("/Users/sebastienvian/Desktop/photos-iphone").extract_all_postions
GeoJsonBuilder.new.convert_to_points( positions ).save('./geojson.json')

