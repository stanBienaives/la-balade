require './extractor.rb'
require './interpolator.rb'


#p Extractor.new.extract "/Users/sebastienvian/Desktop/photos-iphone-as-3/IMG_3177.JPG"

#p Extractor.new.extract_and_save "/Users/sebastienvian/Desktop/photos-iphone-as-3" , "positions.json"
#
#
#
#Extractor.extract_and_save [
  #"/Users/sebastienvian/Desktop/photos-iphone-as-1",
  #"/Users/sebastienvian/Desktop/photos-iphone-as-2",
  #"/Users/sebastienvian/Desktop/photos-iphone-as-3",
  #"/Users/sebastienvian/Desktop/photos-iphone-as",
  #"/Users/sebastienvian/Desktop/photos-iphone-am",
#], "positions.json"


Interpolator.new(tag: "Violet").interpolations( JSON.parse( File.read( "positions.json" ) ) )
