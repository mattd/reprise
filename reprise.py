#!/usr/bin/env python

from __future__ import with_statement

import os
import re
import email
import shutil

from os.path import abspath, realpath, dirname, join
from datetime import datetime
from textwrap import dedent
from markdown import markdown
from smartypants import smartyPants
from jinja2 import DictLoader, Environment

TITLE = 'Redflavor Journal'

AUTHOR = {
    'name': 'Eivind Uggedal',
    'email': 'eu@redflavor.com',
    'url': 'http://redflavor.com',
}

ROOT = abspath(dirname(__file__))
DIRS = {
    'source': join(ROOT, 'entries'),
    'build': join(ROOT, 'build'),
    'public': join(ROOT, 'public'),
    'assets': join(ROOT, 'assets'),
}

def read_and_parse_entries():
    files = sorted([join(DIRS['source'], f)
                    for f in os.listdir(DIRS['source'])], reverse=True)
    entries = []
    for file in files:
        with open(file, 'r') as open_file:
            msg = email.message_from_file(open_file)
            meta = META_REGEX.findall(file)[0]
            date = datetime(*[int(d) for d in meta[0:3]])
            entries.append({
                'slug': slugify(meta[3]),
                'title': meta[3].replace('.', ' '),
                'tags': msg['Tags'].split(),
                'date': {'iso8601': date.isoformat(),
                         'display': date.strftime('%Y-%m-%d'),},
                'content_html': smartyPants(markdown(msg.get_payload())),
            })
    return entries

def generate_index(entries):
    html = env.get_template('list.html').render(author=AUTHOR,
                                                title=TITLE,
                                                feed_url='',
                                                analytics='',
                                                entries=entries)
    write_file(join(DIRS['build'], 'index.html'), html)

def generate_style(css):
    write_file(join(DIRS['build'], 'style.css'), css)

def write_file(file_name, contents):
    with open(file_name, 'w') as open_file:
        open_file.write(contents)

def slugify(str):
    return re.sub(r'\s+', '-', re.sub(r'[^\w\s-]', '',
                                      str.replace('.', ' ').lower()))

def get_templates():
    templates = {
    'base.html': """
    <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN"
    "http://www.w3.org/TR/html4/strict.dtd">
    <html>
      <head>
        <title>{{ title }}</title>
        <link rel='stylesheet' type='text/css' href='/style.css'>
        <link rel="alternate" type="application/atom+xml" title="{{ title }}"
              href="{{ feed_url }}">
      </head>
      <body>
        <h1>
          {% block title %}
          {% endblock %}
        </h1>
        <address class="author vcard">
            <a class="url fn" href="{{ author.url }}">{{ author.name }}</a>
            <br>
            <a class="email" href="mailto:{{ author.email }}">
              {{ author.email }}
            </a>
        </address>
        {% block content %}
        {% endblock %}
      </body>
      <script type='text/javascript'>
        var gaJsHost = (("https:" == document.location.protocol) ?
                       "https://ssl." : "http://www.");
        document.write(unescape("%3Cscript src='" + gaJsHost +
                                "google-analytics.com/ga.js' type='text/" +
                                "javascript'%3E%3C/script%3E"));
      </script>
      <script type='text/javascript'>
        var pageTracker = _gat._getTracker("{{ analytics }}");
        pageTracker._initData();
        pageTracker._trackPageview();
      </script>
    </html>
    """,

    'list.html': """
    {% extends "base.html" %}
    {% block title %}
      {% if active_tag %}
        <a href="/">{{ title }}</a>
      {% else %}
        {{ title }}
      {% endif %}
    {% endblock %}
    {% block content %}
      {% for entry in entries %}
        <div class="hentry">
          <abbr class="updated" title="{{ entry.date.iso8601 }}">
            {{ entry.date.display }}
          </abbr>
          <h2>
            <a href="/{{ entry.slug }}" rel="bookmark">{{ entry.title }}</a>
          </h2>
          <ul class="tags{% if loop.first %} floated{% endif %}">
            {% for tag in entry.tags %}
              <li{% if active_tag == tag %} class="active"{% endif %}>
                <a href="/tags/{{ tag }}" rel="tag" >{{ tag }}</a>
              </li>
            {% endfor %}
          </ul>
          {% if loop.first %}
            <div class="entry-content">{{ entry.content_html }}</div>
          {% endif %}
        </div>
      {% endfor %}
    {% endblock %}
    """,
    'style.css': """
    body {
      font-size: 1em;
      font-family: 'DejaVu Sans', 'Bitstream Vera Sans', Verdana, sans-serif;
      line-height: 1.5;
      padding: 0 10em 0 10em;
      width: 40em;
    }

    abbr.updated, ul.tags.floated {
      float: left;
    }

    abbr.updated {
      border: 0;
      margin: 0.3em 0 0 -7em;
    }

    ul.tags {
      list-style-type: none;
    }

    ul.tags.floated {
      margin: 3em 0 0 -7em;
    }

    ul.tags li {
      display: inline;
    }

    ul.tags.floated li {
      display: block;
    }

    ul.tags a.active {
      background: #fcc;
    }

    ul, ol {
      padding: 0;
    }

    blockquote {
      font-style: italic;
      margin: 0;
    }

    blockquote em {
      font-weight: bold;
    }

    a {
      background: #ffc;
      color: #000;
    }

    h1, address {
      font-style: normal;
      text-align: center;
    }

    address {
      margin: 0 0 2em 0;
    }

    img {
      margin: 1em 0 1em 0;
    }

    h1, h2, h3, abbr.updated, address {
      font-family: Georgia, 'DejaVu Serif', 'Bitstream Vera Serif', serif;
      font-style: normal;
      font-weight: normal;
    }

    h1 a,   h2 a,   h3 a,   abbr.updated a,   address a {
      background: transparent;
    }

    p {
      margin-bottom: 0;
    }

    p + p {
      margin-top: 0;
      text-indent: 1.1em;
    }

    pre > code {
      border: 0.15em solid #eee;
      border-left: 1em solid #eee;
      display: block;
      font-family: 'DejaVu Sans Mono', 'Bitstream Vera Sans Mono',
                   'Lucida Console', monospaced;
      padding: 1em 1em 1em 2em;
    }
    """,}
    return dict([(k, dedent(v).strip()) for k, v in templates.items()])

META_REGEX = re.compile(r"/(\d{4})\.(\d\d)\.(\d\d)\.(.+)")

if __name__ == "__main__":
    templates = get_templates()
    env = Environment(loader=DictLoader(templates))
    all_entries = read_and_parse_entries()
    os.mkdir(DIRS['build'])
    generate_index(all_entries)
    generate_style(templates['style.css'])
    shutil.rmtree(DIRS['public'])
    shutil.move(DIRS['build'], DIRS['public'])
