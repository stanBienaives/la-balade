require './extractor.rb'
require 'active_support/core_ext/hash/indifferent_access'


class Interpolator

  def initialize( options = {} )

    @set_description = options[:set_description] || false
    @print_stats = options[:print_stats] || false

    # options to filter by tag (only OSX )
    # !! Caution in this case the given directory is not used files will be searched in all the computer
    @tag = options[:tag] || false

  end


  def self.interpolations( options = {} )
    self.new( options ).interpolations( options[:inputs] )
  end


  def interpolations( inputs )
    #sort input
    inputs = inputs.map { |i| HashWithIndifferentAccess.new( i ) }
                   .reject { |i| i[:position].nil? }
                   .sort_by { |i| i[:timestamp] }
    # ensure hash with indifferent access
    @positions = []

    files.each do |file|
      @positions.push interpolate( inputs, file )
    end

    cleaning
    indexing
  end


  def interpolate( sorted_positions, file )
    # find matching digect
    matching = sorted_positions.find { |pos| pos[:digest] == Extractor.new.digest_path( file ) }
    if !matching.nil? && !matching[:position].nil?
      p "Found exact match "
      return matching
    end

    # extract date-time with exiftool
    extract = Extractor.extract( Shellwords.escape(file) )
    raise "extract is nil" if extract.empty?
    extract = extract.first


    # else interpolate
    interval = sorted_positions.find_index { |pos| pos[:timestamp] > extract[:timestamp] }
    previousp = sorted_positions[interval]
    nextp     = sorted_positions[interval +1 ]

    t,t1,t2 = extract[:timestamp].to_f, previousp[:timestamp].to_f, nextp[:timestamp].to_f
    position = {}

    ratio = (t - t1) / ( t2 - t1 )

    %i(latitude longitude).each do |card|
      # ratio = (position[card] - previous[:position][card] ) / (nextp[:position][card] - previous[:position][card] )
      position[card] = (nextp[:position][card] - previousp[:position][card]) * ratio + previousp[:position][card]

    end
    extract[:position] = position
    p extract
    return extract
  end


  # find all files based on tag
  def files
    @files ||= %x(mdfind 'kMDItemUserTags == #{@tag}').split(/\n/)
  end

  private

  # set index on each position
  def indexing
    index = 0;
    @positions.sort_by! { |d| d[:timestamp] }
                   .each { |d| index = index+1 ; d[:index] = index }
  end

  # remove photos with no positions
  def cleaning
    @positions.reject! { |d| d[:position].nil? }
  end


end
