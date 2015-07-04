require './extractor.rb'
require './interpolator.rb'
require './geo_json_builder.rb'


#Extractor.extract_and_save [
  #"/Users/sebastienvian/Desktop/photos-iphone-am",
  #"/Users/sebastienvian/Desktop/photos-iphone-as",
  #"/Users/sebastienvian/Desktop/photos-iphone-as-2",
  #"/Users/sebastienvian/Desktop/photos-iphone-as-3",
  #"/Users/sebastienvian/Desktop/selection-videos"
#], "positions.json"

positions = JSON.parse File.read( "positions.json" )
videos = Interpolator.new(tag: "Violet").interpolations( positions )

GeoJsonBuilder.new.convert_to_points( videos ,
  { "marker-color" => "#f86767", "marker-symbol" => "cinema", "marker-size" => "medium"} ).save('./front/videos.json')

# save all points
#GeoJsonBuilder.new.convert_to_line_string( images ).save('./images.json')
