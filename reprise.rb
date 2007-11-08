%w(rubygems sinatra redcloth).each { |lib| require lib }

TITLE = 'Reprise'

get '/style.css' do
  header 'Content-Type' => 'text/css'
  style
end

get '/' do
  @entries = entries
  haml index
end

get '/:slug' do
  @entry = nil
  entries.each do |entry|
    if entry[:slug] == params[:slug]
      @entry = entry
      break
    end
  end
  @entry ? haml(entry) : status(404)
end

private

  # Returns all textual entries with file names and meta data.
  def entries
    Dir[File.dirname(__FILE__) + '/entries/*'].sort.reverse.collect do |file|
      { :body => File.read(file) }.merge(meta_from_filename(file))
    end
  end

  # Returns an entry's filename, date, title, and slug.
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

  # Parses text from markdown to html.
  def markdown(text)
    RedCloth.new(text).to_html(:markdown)
  end

  # View layout. Takes a title and the main content.
  def layout(title, content)
    %Q(
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN"
"http://www.w3.org/TR/html4/strict.dtd">
%html
  %head
    %title #{title}
    %link{ :href => '/style.css', :rel => 'stylesheet', :type => 'text/css' }
  %body
    #{content}
    )
  end

  # View for the index page.
  def index
    content = %q(
    %h1= TITLE
    - @entries.each do |entry|
      %h2
        = "#{entry[:date]}:"
        %a{ :href => "/#{entry[:slug]}" }
          = entry[:title]
      .entry= markdown(entry[:body])
    )
    layout(TITLE, content)
  end

  # View for entry pages.
  def entry
    content = %q(
    %h1
      %a{ :href => '/' }
        = TITLE
    %h2
      = "#{@entry[:date]}:"
      = @entry[:title]
    .entry= markdown(@entry[:body])
    )
    layout("#{TITLE}: #{@entry[:title]}", content)
  end

  # Stylesheet.
  def style
    %q(
body {
  font-family: monospace;
  width: 45em;
}
    )
  end
