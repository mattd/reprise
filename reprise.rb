require 'rubygems'
require 'sinatra'

get '/' do
  @entries = entries
  haml :index
end

get '/:slug' do
  @entry = nil
  entries.each do |entry|
    if entry[:slug] == params[:slug]
      @entry = entry
      break
    end
  end
  haml :entry
end

private

  # Returns all textual entries with file names.
  def entries
    Dir[File.dirname(__FILE__) + '/entries/*'].reverse.collect do |file|
      { :body => File.read(file) }.merge(meta_from_filename(file))
    end
  end

  # Parses an entry's filename into date, slug, and title.
  def meta_from_filename(file)
    filename = File.basename(file)
    results = filename.scan(/([\d]{4}.\d\d.\d\d)\.(.+)/).first
    date = Date.parse(results[0])
    title = results[1].gsub(/\./, ' ')

    { :filename => filename,
      :date => date, 
      :title => title,
      :slug => slugify(title) }
  end

  # Removes non-alphanumeric characters and substitutes spaces for hyphens.
  def slugify(string)
    string.gsub(/[^\w\s-]/, '').gsub(/\s+/, '-').downcase
  end
