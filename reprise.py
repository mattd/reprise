#!/usr/bin/env python

from textwrap import dedent
from jinja2 import DictLoader, Environment

author = {
    'name': 'Eivind Uggedal',
    'email': 'eu@redflavor.com',
    'url': 'http://redflavor.com',
}

templates = {
    'base.html': """
    <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN"
    "http://www.w3.org/TR/html4/strict.dtd">
    <html>
      <head>
        <title>{{ title }}</title>
        <link rel="alternate" type="application/atom+xml" title="{ title }"
              href="{ feed_url }"
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
          <abbr class="updated" title="{{ entry.date_iso8601 }}">
            {{ entry.date_display }}
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
}
templates = dict([(k, dedent(v).strip()) for k, v in templates.items()])

if __name__ == "__main__":
    env = Environment(loader=DictLoader(templates))
    print env.get_template('list.html').render(author=author)
