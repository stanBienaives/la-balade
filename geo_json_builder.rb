
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

