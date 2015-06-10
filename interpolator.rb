
class Interpolator

  def initialize( options = {} )
    @positions = options[:positions]

    @set_description = options[:set_description] || false
    @print_stats = options[:print_stats] || false

    # options to filter by tag (only OSX )
    # !! Caution in this case the given directory is not used files will be searched in all the computer
    @tag = options[:tag] || false

  end


  def interpolate( input, directories )
    
  end


  # find all files based on tag
  def files
    @files = %x(mdfind 'kMDItemUserTags == #{tag}').split(/\n/)
  end


end
