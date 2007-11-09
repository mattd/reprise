# Copyright (c) 2007 Eivind Uggedal <eu@redflavor.com>
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
# Reprise - As minimal a blog as possible
#
# Usage:
#
#   1. gem install sinatra haml bluecloth -y
#   2. wget redflavor.com/reprise.rb
#   3. mkdir entries
#   4. vi entries/YYYY.MM.DD.Title.Goes.Here
#   5. ruby reprise.rb

%w(rubygems sinatra bluecloth).each { |lib| require lib }

sessions :off

TITLE = 'Reprise'

get 404 do
  haml fourofour
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
  if @entry
    haml entry
  else
    status 404
    haml fourofour
  end
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
    BlueCloth.new(text).to_html
  end

  # View layout. Takes a title and the main content.
  def layout(title, content)
    %Q(
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN"
"http://www.w3.org/TR/html4/strict.dtd">
%html
  %head
    %title #{title}
    %style{ :type => 'text/css' }
      body { font-family: monospace; width: 45em; }
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

  # View for the 404 page.
  def fourofour
    content = %q(
    %h1= TITLE
    Resource not found. Go back to
    %a{ :href => '/' } the front
    page.
    )
    layout("#{TITLE}: Resource not found", content)
  end
