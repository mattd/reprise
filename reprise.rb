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

%w(rubygems sinatra bluecloth rubypants haml).each { |lib| require lib }

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

sessions :off
static '/images', 'images'

TITLE = 'Research Journal'
AUTHOR = { :name => 'Eivind Uggedal',
           :email => 'eu@redflavor.com',
           :url => 'http://redflavor.com' }

get 404 do
  haml fourofour
end

get '/' do
  @entries, @tasklist = entries, tasklist
  haml index
end

get '/style.css' do
  header 'Content-Type' => 'text/css'
  Sass::Engine.new(stylesheet).render
end

get '/:slug' do
  @entry = nil
  entries.each do |entry|
    if entry[:slug] == params[:slug]
      @entry = entry
      break
    end
  end
  @entry ? haml(entry) : (status 404; haml fourofour)
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

  # Returns an array of task items.
  def tasklist(file=File.dirname(__FILE__) + '/tasks')
    File.read(file).split("\n\n") if File.exists? file
  end

  # Removes non-alphanumeric characters and substitutes spaces for hyphens.
  def slugify(string)
    string.gsub(/[^\w\s-]/, '').gsub(/\s+/, '-').downcase
  end

  # Parses text from mardown to nice html.
  def htmlify(text)
    RubyPants.new(BlueCloth.new(text).to_html).to_html
  end

  # View layout. Takes a title and the main content.
  def layout(title, content)
    %Q(
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN"
"http://www.w3.org/TR/html4/strict.dtd">
%html
  %head
    %title #{title}
    %meta{ 'http-equiv' => 'Content-Type', :content => 'text/html;charset=utf-8' }
    %link{ :rel => 'stylesheet', :type => 'text/css', :href => '/style.css' }
    %link{ :rel => 'alternate', :type => 'application/atom+xml', :title => '#{TITLE}', :href => 'http://feeds.feedburner.com/redflavor' }
  %body
    #{content}
    %address.author.vcard
      %a.url.fn{ :href => '#{AUTHOR[:url]}' } #{AUTHOR[:name]}
      %a.email{ :href => 'mailto:#{AUTHOR[:email]}' } #{AUTHOR[:email]}
      )
  end

  # Haml template for the index page.
  def index
    content = %q(
    %h1
      %a{ :href=> 'http://feeds.feedburner.com/redflavor', :title => 'Newsfeed' }
        %img.feed{ :src => '/images/feed.icon.png', :alt => 'Newsfeed' }
      = TITLE
    - if @tasklist && @tasklist.any?
      %h2 Tasks
      %ol#tasklist
        - @tasklist.each do |task|
          %li= task
    - @entries.each do |entry|
      .hentry
        %h2
          %abbr.updated{ :title => entry[:date].iso8601 }= entry[:date]
          %a.entry-title{ :href => "/#{entry[:slug]}", :rel => 'bookmark' }
            = entry[:title]
        .entry-content= htmlify(entry[:body])
    )
    layout(TITLE, content)
  end

  # Haml template for entry pages.
  def entry
    content = %q(
    %h1
      %a{ :href => '/' }
        = TITLE
    .hentry
      %h2
        %abbr.updated{ :title => @entry[:date].iso8601 }= @entry[:date]
        %span.entry-title= @entry[:title]
      .entry-content= htmlify(@entry[:body])
    )
    layout("#{TITLE}: #{@entry[:title]}", content)
  end

  # Haml template for the 404 page.
  def fourofour
    content = %q(
    %h1= TITLE
    Resource not found. Go back to
    %a{ :href => '/' } the front
    page.
    )
    layout("#{TITLE}: Resource not found", content)
  end

  # Sass template for the CSS stylesheet.
  def stylesheet
    %q(
body
  :line-height 1.4
  :width 94%
abbr
  :border 0
.entry-content, #tasklist
  :-moz-column-width 28em
  :-moz-column-gap 1.5em
  :-webkit-column-width 28em
  :-webkit-column-gap 1.5em
ol li
  :margin-right 1em
a
  :background #ffb
  :color #000
h1, h2
  :font-weight normal
  a
    :background #fe7
    :text-decoration none
img.feed
  :border 0
  :float right
p
  :margin-bottom 0
p + p
  :margin-top 0
  :text-indent 1.1em
address
  :margin 2em 0 0 0
    )
  end
