# Copyright (c) 2007-2008 Eivind Uggedal <eu@redflavor.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#
#
# Reprise - As minimal a hAtom blog as possible
#
# Usage:
#
#   1. gem install sinatra haml bluecloth rubypants -y
#   2. wget redflavor.com/reprise.rb
#   3. mkdir entries
#   4. vi entries/YYYY.MM.DD.Title.Goes.Here
#   5. ruby reprise.rb

$: << File.expand_path("../../sinatra/lib", __FILE__)
%w(sinatra rubygems bluecloth rubypants haml).each { |lib| require lib }

# Format of time objects.
class Time
  def to_s
    self.strftime('%Y-%m-%d')
  end
end

# Monkey patch for rendering haml templates as html.
Haml::Precompiler.module_eval do
  def prerender_tag(name, atomic, attributes)
    a = Haml::Precompiler.build_attributes(@options[:attr_wrapper], attributes)
    "<#{name}#{a}>"
  end
end

TITLE = 'Research Journal'
AUTHOR = { :name => 'Eivind Uggedal',
           :email => 'eu@redflavor.com',
           :url => 'http://redflavor.com' }
ANALYTICS = 'UA-1857692-3'

get 404 do
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
  @entry = nil
  entries.each do |entry|
    if entry[:slug] == params[:slug]
      @entry = entry
      @title = "#{TITLE}: #{entry[:title]}"
      break
    end
  end
  @entry ? haml(:entry) : (status 404; haml :fourofour)
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
    %link{ :rel => 'alternate', :type => 'application/atom+xml', :title => '#{TITLE}', :href => 'http://feeds.feedburner.com/redflavor' }
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
- @entries.each do |entry|
  .hentry
    %abbr.updated{ :title => entry[:date].iso8601 }= entry[:date]
    %h2
      %a.entry-title{ :href => "/#{entry[:slug]}", :rel => 'bookmark' }
        = entry[:title]
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
%h1= TITLE
Resource not found. Go back to
%a{ :href => '/' } the front
page.
)

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
  :background #ffb
  :color #000
h1, address
  :font-style normal
  :text-align center
address
  :margin 0 0 2em 0
 
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
