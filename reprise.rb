#!/usr/bin/env ruby
%w(rubygems
   bluecloth
   rubypants
   haml
   sass
   stringio
   mailread
   time).each { |lib| require lib }

TITLE = 'Redflavor Journal'
AUTHOR = { :name => 'Eivind Uggedal',
           :email => 'eu@redflavor.com',
           :url => 'http://redflavor.com' }
ANALYTICS = 'UA-1857692-3'
PUBLIC = File.join(File.dirname(__FILE__), 'public')
ASSETS = File.join(File.dirname(__FILE__), 'assets')

# Format of time objects.
class Time
  def to_s
    self.strftime('%Y-%m-%d')
  end
end

# Stolen from Sinatra
def templates
  templates = {}

  eof = IO.read(caller.first.split(':').first).split('__FILE__').last
  data = StringIO.new(eof)

  current_template = nil
  data.each do |line|
    if line =~ /^##\s?(.*)/
      current_template = $1.to_sym
      templates[current_template] = ''
    elsif current_template
      templates[current_template] << line
    end
  end
  templates
end

def slugify(string)
  string.gsub(/[^\w\s-]/, '').gsub(/\s+/, '-').downcase
end

def htmlify(text)
  RubyPants.new(BlueCloth.new(text).to_html).to_html
end

def entries
  files = Dir[File.dirname(__FILE__) + '/entries/*'].sort.reverse
  files.collect do |file|
    meta_from_file(file)
  end
end

def meta_from_file(file)
  msg = Mail.new(file)
  tags = msg['Tags'].split
  filename = File.basename(file)
  results = filename.scan(/([\d]{4}).(\d\d).(\d\d)\.(.+)/).first
  date = Time.local(*results[0..2])
  title = results[3].gsub(/\./, ' ')

  { :body => msg.body.join(""),
    :tags => tags,
    :filename => filename,
    :date => date, 
    :title => title,
    :slug => slugify(title) }
end

def write_file(fname, data, root=PUBLIC)
  File.open(File.join(root, fname), 'w') { |f| f.puts data }
end

def create_dir(dirname, root=PUBLIC)
  FileUtils.mkdir_p File.join(root, dirname)
end

def clean_public
  FileUtils.rm_r PUBLIC if File.exists? PUBLIC
  FileUtils.mkdir_p PUBLIC
end

def generate_style
  style = Sass::Engine.new(templates[:style]).render
  write_file('style.css', style)
end

def render_haml(template, bind=binding)
  Haml::Engine.new(templates[:layout], {:format => :html4}).render(bind) do
    Haml::Engine.new(templates[template], {:format => :html4}).render(bind)
  end
end

def generate_fourofour
  fourofour = render_haml(:fourofour, binding)
  write_file('404.html', fourofour)
end

def generate_index
  @entries = entries
  index = render_haml(:index, binding)
  write_file('index.html', index)
end

def generate_tag_indexes
  all_entries = entries
  all_tags = all_entries.collect { |entry| entry[:tags] }.flatten.uniq
  all_tags.each do |tag_slug|
    @entries = all_entries.select { |entry| entry[:tags].include? tag_slug }
    @active_tag = tag_slug
    tag_index = render_haml(:index, binding)
    create_dir("/tags/#{tag_slug}")
    write_file("/tags/#{tag_slug}/index.html", tag_index)
  end
end

def generate_entries
  entries.each do |entry|
    @entry = entry
    @title = "#{TITLE}: #{@entry[:title]}"
    rendered = render_haml(:entry, binding)
    write_file("#{@entry[:slug]}.html", rendered)
  end
end


def distribute_assets
  FileUtils.cp_r "#{ASSETS}/.", PUBLIC
end

if __FILE__ == $0
  clean_public
  generate_style
  generate_fourofour
  generate_index
  generate_tag_indexes
  generate_entries
  distribute_assets
end

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
      %ul.tags
        - entry[:tags].each do |tag|
          %li
          - if tag == @active_tag
            %a.active{ :href => "/tags/#{tag}", :rel => 'tag' }= tag
          - else
            %a{ :href => "/tags/#{tag}", :rel => 'tag' }= tag
      .entry-content~ htmlify(entry[:body])
    - else
      %ul.tags.inline
        - entry[:tags].each do |tag|
          %li
            - if tag == @active_tag
              %a.active{ :href => "/tags/#{tag}", :rel => 'tag' }= tag
            - else
              %a{ :href => "/tags/#{tag}", :rel => 'tag' }= tag

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
  %ul.tags
    - @entry[:tags].each do |tag|
      %li
        %a{ :href => "/tags/#{tag}", :rel => 'tag' }= tag
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
abbr.updated, ul.tags
  :float left
abbr.updated
  :border 0
  :margin 0.3em 0 0 -7em
ul.tags
  :list-style-type none
  :margin 3em 0 0 -7em
ul.tags.inline
  :float none
  :margin 0
ul.tags.inline li
  :display inline
ul.tags a.active
  :background #fcc
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
  :font-family 'DejaVu Sans Mono', 'Bitstream Vera Sans Mono', "Lucida Console", "monospaced
  :padding 1em 1em 1em 2em
