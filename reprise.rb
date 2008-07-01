%w(rubygems sinatra bluecloth rubypants haml sass).each { |lib| require lib }

TITLE = 'Research Journal'
AUTHOR = { :name => 'Eivind Uggedal',
           :email => 'eu@redflavor.com',
           :url => 'http://redflavor.com' }
ANALYTICS = 'UA-1857692-3'

# Format of time objects.
class Time
  def to_s
    self.strftime('%Y-%m-%d')
  end
end

not_found do
  haml :fourofour
end

get '/' do
  @entries = entries
  haml :index
end

get '/style.css' do
  header 'Content-Type' => 'text/css'

  Sass::Engine.new(Sinatra.application.templates[:style]).render
end

get '/:slug' do
  @entry = entries.detect do |entry|
    entry[:slug] == params[:slug]
  end
  raise Sinatra::NotFound unless @entry

  @title = "#{TITLE}: #{@entry[:title]}"

  haml :entry
end

private

  # Returns all textual entries with file names and meta data.
  def entries
    files = Dir[File.dirname(__FILE__) + '/entries/*'].sort.reverse
    files.collect do |file|
      { :body => File.read(file) }.merge(meta_from_filename(file))
    end
  end

  # Returns an entry's filename, date, title, and slug.
  def meta_from_filename(file)
    filename = File.basename(file)
    results = filename.scan(/([\d]{4}).(\d\d).(\d\d)\.(.+)/).first
    date = Time.local(*results[0..2])
    title = results[3].gsub(/\./, ' ')

    { :filename => filename,
      :date => date, 
      :title => title,
      :slug => slugify(title) }
  end

  # Removes non-alphanumeric characters and substitutes spaces for hyphens.
  def slugify(string)
    string.gsub(/[^\w\s-]/, '').gsub(/\s+/, '-').downcase
  end

  # Parses text from mardown to nice html.
  def htmlify(text)
    RubyPants.new(BlueCloth.new(text).to_html).to_html
  end

  use_in_file_templates!

__END__

## layout
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN"
"http://www.w3.org/TR/html4/strict.dtd">
%html
  %head
    %title= @title ? @title : TITLE
    %meta{ 'http-equiv' => 'Content-Type', :content => 'text/html;charset=utf-8' }
    %link{ :rel => 'stylesheet', :type => 'text/css', :href => '/style.css' }
    %link{ :rel => 'alternate', :type => 'application/atom+xml', :title => TITLE, :href => 'http://feeds.feedburner.com/redflavor' }
  %body
    = yield
  %script{ :type => 'text/javascript'}
    var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
    document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
  %script{ :type => 'text/javascript'}
    = "var pageTracker = _gat._getTracker(\"#{ANALYTICS}\");"
    pageTracker._initData();
    pageTracker._trackPageview();

## index
%h1= TITLE
%address.author.vcard
  %a.url.fn{ :href => AUTHOR[:url] }= AUTHOR[:name]
  %br
  %a.email{ :href => "mailto:#{AUTHOR[:email]}" }= AUTHOR[:email]
- @entries.each_with_index do |entry, i|
  .hentry
    %abbr.updated{ :title => entry[:date].iso8601 }= entry[:date]
    %h2
      %a.entry-title{ :href => "/#{entry[:slug]}", :rel => 'bookmark' }
        = entry[:title]
    - if i == 0
      .entry-content~ htmlify(entry[:body])

## entry
%h1
  %a{ :href => '/' }= TITLE
%address.author.vcard
  %a.url.fn{ :href => AUTHOR[:url] }= AUTHOR[:name]
  %br
  %a.email{ :href => "mailto:#{AUTHOR[:email]}" }= AUTHOR[:email]
.hentry
  %abbr.updated{ :title => @entry[:date].iso8601 }= @entry[:date]
  %h2
    %span.entry-title= @entry[:title]
  .entry-content~ htmlify(@entry[:body])

## fourofour
%h1
  %a{ :href => '/' }= TITLE
%address.author.vcard
  %a.url.fn{ :href => AUTHOR[:url] }= AUTHOR[:name]
  %br
  %a.email{ :href => "mailto:#{AUTHOR[:email]}" }= AUTHOR[:email]
%p
  Resource not found. Go back to
  %a{ :href => '/' } the front
  page.

## style
body
  :font-size 90%
  :font-family 'DejaVu Sans', 'Bitstream Vera Sans', Verdana, sans-serif
  :line-height 1.5
  :padding 0 10em 0 10em
  :width 40em
abbr
  :border 0
  :float left
  :margin 0.3em 0 0 -7em
ul, ol
  :padding 0
blockquote
  :font-style italic
  :margin 0
blockquote em
  :font-weight bold
a
  :background #ffc
  :color #000
h1, address
  :font-style normal
  :text-align center
address
  :margin 0 0 2em 0
img
  :margin 1em 0 1em 0
h1, h2, h3, abbr.updated, address
  :font-family Georgia, 'DejaVu Serif', 'Bitstream Vera Serif', serif
  :font-style normal
  :font-weight normal
  a
    :background transparent
p
  :margin-bottom 0
p + p
  :margin-top 0
  :text-indent 1.1em
pre > code
  :border 0.15em solid #eee
  :border-left 1em solid #eee
  :display block
  :font-family 'DejaVu Sans Mono', 'Bitstream Vera Sans Mono', monospaced
  :padding 1em 1em 1em 2em
