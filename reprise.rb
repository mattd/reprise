require 'rubygems'
require 'sinatra'

get '/' do
  @entries = entries
  haml :index
end

# Returns all textual entries with file names.
def entries
  Dir[File.dirname(__FILE__) + '/entries/*'].reverse.collect do |file|
    { :body => File.read(file) }.merge(meta_from_filename(file))
  end
end

# Parses an entry's filename into date, slug, and title.
def meta_from_filename(file)
  filename = File.basename(file)
  results = filename.scan(/(\d\d\d\d\.\d\d.\d\d)\.(.+)/).first
  date = Date.parse(results[0])
  slug = results[1].gsub(/\./, '-')
  title = results[1].gsub(/\./, ' ')

  { :filename => filename,
    :title => title,
    :date => date }
end
