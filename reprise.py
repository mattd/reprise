#!/usr/bin/env python

from __future__ import with_statement

import os
import re
import time
import email
import shutil

import markdown

from os.path import abspath, realpath, dirname, join
from datetime import datetime, timedelta
from textwrap import dedent
from pygments.formatters import HtmlFormatter
from smartypants import smartyPants
from jinja2 import DictLoader, Environment
from lxml.builder import ElementMaker
from lxml.etree import tostring

TITLE = 'bytexbyte'
URL = 'http://bytexbyte.com'
STYLESHEET = 'styles.css'

AUTHOR = {
    'name': 'Matt Dawson',
    'url': 'http://bytexbyte.com',
    'elsewhere': {
        'Dawsoning': 'http://dawsoning.com/',
        'delicious': 'http://delicious.com/matthewtdawson/',
        'Facebook': 'http://facebook.com/mattdawson/',
        'flickr': 'http://flickr.com/photos/matthewtdawson/',
        'The Nested Float': 'http://thenestedfloat.com/',
        'twitter': 'http://twitter.com/mattdawson/',
    }
}

ROOT = abspath(dirname(__file__))
DIRS = {
    'source': join(ROOT, 'entries'),
    'build': join(ROOT, 'build'),
    'public': join(ROOT, 'public'),
    'assets': join(ROOT, 'assets'),
}

CONTEXT = {
    'author': AUTHOR,
    'stylesheet': STYLESHEET,
    'head_title': "%s" % TITLE,
}

def _markdown(content):
    return markdown.markdown(content, ['codehilite', 'def_list'])

def read_and_parse_entries():
    files = sorted([join(DIRS['source'], f)
                    for f in os.listdir(DIRS['source'])], reverse=True)
    entries = []
    for file in files:
        match = META_REGEX.findall(file)
        if len(match):
            meta = match[0]
            with open(file, 'r') as open_file:
                msg = email.message_from_file(open_file)
                date = datetime(*[int(d) for d in meta[0:3]])
                entries.append({
                    'slug': slugify(meta[3]),
                    'title': meta[3].replace('.', ' '),
                    'tags': msg['Tags'].split(),
                    'date': {'iso8601': date.isoformat(),
                             'rfc3339': rfc3339(date),
                             'display': date.strftime('%B %d, %Y'),},
                    'content_html': smartyPants(_markdown(msg.get_payload())),
                })
    return entries

def generate_index(entries, template):
    feed_url = "%s/index.atom" % URL
    html = template.render(dict(CONTEXT, **{'entries': entries,
                                            'feed_url': feed_url}))
    write_file(join(DIRS['build'], 'index.html'), html)
    atom = generate_atom(entries, feed_url)
    write_file(join(DIRS['build'], 'index.atom'), atom)

def generate_tag_indices(entries, template):
    for tag in set(sum([e['tags'] for e in entries], [])):
        tag_entries = [e for e in entries if tag in e['tags']]
        feed_url = "%s/tags/%s.atom" % (URL, tag)
        html = template.render(
            dict(CONTEXT, **{'entries': tag_entries,
                             'active_tag': tag,
                             'feed_url': feed_url,
                             'head_title': "%s: %s" % (CONTEXT['head_title'],
                                                       tag),}))
        write_file(join(DIRS['build'], 'tags', '%s.html' % tag), html)
        atom = generate_atom(tag_entries, feed_url)
        write_file(join(DIRS['build'], 'tags', '%s.atom' % tag), atom)

def generate_details(entries, template):
    for entry in entries:
        html = template.render(
            dict(CONTEXT, **{'entry': entry,
                             'head_title': "%s: %s" % (CONTEXT['head_title'],
                                                       entry['title'])}))
        write_file(join(DIRS['build'], '%s.html' % entry['slug']), html)

def generate_404(template):
        html = template.render(CONTEXT)
        write_file(join(DIRS['build'], '404.html'), html)

def generate_style(css):
    css2 = HtmlFormatter(style='trac').get_style_defs()
    write_file(join(DIRS['build'], STYLESHEET), ''.join([css, "\n\n", css2]))

def generate_atom(entries, feed_url):
    A = ElementMaker(namespace='http://www.w3.org/2005/Atom',
                     nsmap={None : "http://www.w3.org/2005/Atom"})
    entry_elements = []
    for entry in entries:
        entry_elements.append(A.entry(
            A.id(atom_id(entry=entry)),
            A.title(entry['title']),
            A.link(href="%s/%s" % (URL, entry['slug'])),
            A.updated(entry['date']['rfc3339']),
            A.content(entry['content_html'], type='html'),))
    return tostring(A.feed(A.author( A.name(AUTHOR['name']) ),
                           A.id(atom_id()),
                           A.title(TITLE),
                           A.link(href=URL),
                           A.link(href=feed_url, rel='self'),
                           A.updated(entries[0]['date']['rfc3339']),
                           *entry_elements), pretty_print=True)

def write_file(file_name, contents):
    with open(file_name, 'w') as open_file:
        open_file.write(contents.encode("utf-8"))

def slugify(str):
    return re.sub(r'\s+', '-', re.sub(r'[^\w\s-]', '',
                                      str.replace('.', ' ').lower()))

def atom_id(entry=None):
    domain = re.sub(r'http://([^/]+).*', r'\1', URL)
    if entry:
        return "tag:%s,%s:/%s" % (domain, entry['date']['display'],
                                  entry['slug'])
    else:
        return "tag:%s,2009-03-04:/" % domain

def rfc3339(date):
    offset = -time.altzone if time.daylight else -time.timezone
    return (date + timedelta(seconds=offset)).strftime('%Y-%m-%dT%H:%M:%SZ')

def get_templates():
    templates = {
    'base.html': """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <title>{{ head_title }}</title>
        <meta charset="UTF-8">
        <link rel="stylesheet" type="text/css" href="/{{ stylesheet }}">
        <link rel="alternate" type="application/atom+xml"
              title="{{ head_title }}" href="{{ feed_url }}">
        <link rel="openid.server" href="http://www.myopenid.com/server" />
        <link rel="openid.delegate" href="http://mattdawson.myopenid.com/" />
      </head>
      <body>
        <a href="http://github.com/mattd"><img class="ribbon"
        src="http://s3.amazonaws.com/github/ribbons/forkme_right_white_ffffff.png"
        alt="Fork me on GitHub"></a>
        <section id="site-info">
          <header>
            <h2>busy building</h2>
            <h1><a href="/">byte<span>x</span>byte</a></h1>
          </header>
          <article>
            <p>is the programming journal of <a
            href="http://www.google.com/profiles/matthewtdawson">
            {{ author.name }}</a>, a professional web developer and tech junkie 
            from Charlottesville, VA USA.</p>
            <p>Wanna get in touch? Email matt at this domain dot com.  I'll be 
            pleasant. Promise.</p>
            <p><strong>Elsewhere:</strong>
            {% for service, url in author.elsewhere.items() %}
              <a href="{{ url }}">{{ service }}</a>{% if not loop.last %},
              {% endif %}
            {% endfor %}
            </p>
          </article>
        </section><!--/#site-info-->
        {% block content %}
        {% endblock %}
        <footer>
          <nav>
            <strong>feeds:</strong> <a href="{{ feed_url }}">atom</a>
          </nav>
          <p>&copy; {{ author.name }}. 
          <a href="http://github.com/uggdeal/reprise/"> Reprise</a> powered.
          Hosted in <a href="http://rackspacecloud.com"> the cloud</a>.</p>
        </footer>
      </body>
    </html>
    """,

    'list.html': """
    {% extends "base.html" %}
    {% block content %}
      <section id="previews">
      {% for entry in entries %}
        {% include '_preview.html' %}
      {% endfor %}
      </section><!--/#previews-->
    {% endblock %}
    """,

    'detail.html': """
    {% extends "base.html" %}
    {% block content %}
      <section id="writing">
        {% include '_entry.html' %}
      </section><!--/#writing-->
    {% endblock %}
    """,

    '_preview.html': """
    <article class="clearfloat">
      <header>
        <time datetime="{{ entry.date.iso8601 }}">
          {{ entry.date.display }}
        </time>
        <h2><a href="/{{ entry.slug }}" rel="bookmark">
          {{ entry.title }}
        </a></h2>
      </header>
      <section class="body">
        <p>{{ entry.content_html|striptags|truncate(300) }} //
        <a href="/{{ entry.slug }}">Continue</a>.</p>
        <p class="tags"><strong>Tags:</strong>
          {% for tag in entry.tags %}
            <a href="/tags/{{ tag }}" rel="tag">{{ tag }}</a>{% if not loop.last %},
            {% endif %}
          {% endfor %}
        </p>
      </section><!--/.body-->
    </article>
    """,

    '_entry.html': """
    <article class="clearfloat">
      <header>
        <time datetime="{{ entry.date.iso8601 }}">
          {{ entry.date.display }}
        </time>
        <h2><a href="/{{ entry.slug }}" rel="bookmark">
          {{ entry.title }}
        </a></h2>
      </header>
      <section class="body">
        {{ entry.content_html }}
        <p class="tags"><strong>Tags:</strong>
          {% for tag in entry.tags %}
            <a href="/tags/{{ tag }}" rel="tag">{{ tag }}</a>{% if not loop.last %},
            {% endif %}
          {% endfor %}
        </p>
      </section><!--/.body-->
    </article>
    """,

    '404.html': """
    {% extends "base.html" %}
    {% block content %}
      <p>Resource not found. Go back to <a href="/">the front</a> page.</p>
    {% endblock %}
    """,

    STYLESHEET: """
    /* ----- the reset ----- */

    html, body, div, span, applet, object, iframe,
    h1, h2, h3, h4, h5, h6, p, blockquote, pre,
    a, abbr, acronym, address, big, cite, code,
    del, dfn, em, font, img, ins, kbd, q, s, samp,
    small, strike, strong, sub, sup, tt, var,
    b, u, i, center,
    dl, dt, dd, ol, ul, li,
    fieldset, form, input, label, legend,
    table, caption, tbody, tfoot, thead, tr, th, td {
        margin: 0;
        padding: 0;
    }

    /* ----- the basics ----- */

    body {
        background:#0c0c0c;
        color:#fff;
        font-family: 'Helvetica Neue', helvetica, arial, sans-serif;
        font-size:16px;
        padding-top:20px;
    }

    p {
        line-height:28px;
        margin-top:28px;
        margin-bottom:28px;
    }

    a {
        color:#fff;
        outline:none;
    }

    a:hover {
        background:#bc0d3c;
        text-decoration:none;
    }

    pre {
        background:#000;
        line-height:28px;
    }

    pre code {
        display:block;
        padding:24px 20px 32px;
        overflow:scroll;
    }

    code {
        background:#000;
        padding:0 5px;
    }

    abbr {
        border-bottom:1px dotted #fff;
        cursor:help;
    }

    blockquote {
        background:#161616;
        font-family:georgia,serif;
        font-style:italic;
        padding:28px 34px;
    }

    blockquote p {
        margin:0;	
    }

    /* ----- the sidebar ----- */

    #site-info {
        position:absolute;
        top:60px;
        left:720px;
        overflow:hidden;
        width:360px;
    }

    #site-info header h1 {
        font-size:76px;
        line-height:84px;
        margin:33px 0 -7px;
    }

    #site-info header h1 a {
        text-decoration:none;
        text-shadow:0 2px 2px #000;
    }

    #site-info header h1 a:hover {
        background:none;
        color:#cd0053;
    }

    #site-info header h1 a span {
        color:#cd0053;
    }

    #site-info header h1 a:hover span {
        color:#fff;
    }

    #site-info header h2 {
        color:#8c8c8c;
        font-size:24px;
        line-height:28px;
        margin:2px 0 -40px;
    }

    #site-info article {
        color:#8c8c8c;
        line-height:1.8em;
    }

    /* ----- the articles ----- */

    #writing,
    #previews {
        background:#1c1c1c;
        border-right:20px solid #161616;
        border-left:20px solid #161616;
        display:block;
        height:100%;
        margin:0 0 0 20px;
        padding:28px 36px 56px 0;
        width:604px;
    }

    #writing article,
    #previews article {
        clear:both;
        display:block;
    }

    #writing article header h2 a,
    #previews article header h2 a {
        background:#b7003d;	
        border-left:20px solid #920031;
        color:#fff;
        float:left;
        font-size:42px;
        line-height:56px;
        margin-bottom:20px;
        margin-left:-20px;
        padding:2px 20px 6px;
        text-decoration:none;
        text-shadow:0 2px 2px #0c0c0c;
    }

    #writing article header h2 a:hover,
    #previews article header h2 a:hover {
        background:#920031;
        border-left:20px solid #6e0025;
    }

    #writing article header time,
    #previews article header time {
        color:#8c8c8c;
        display:block;
        line-height:28px;
        margin:16px 0 12px 20px;
        text-shadow:0 1px 1px #0c0c0c;
    }

    #writing article section,
    #previews article section {
        clear:both;
        display:block;
        margin-left:20px;
    }

    #writing article ol,
    #writing article ul {
        margin-left:60px;
    }

    #writing article ol li,
    #writing article ul li {
        line-height:28px;
    }

    #writing article h3 {
        font-size:24px;
        line-height:28px;
        margin:28px 0;
    }

    p.tags {
        margin:-14px 0 42px;
    }

    p.tags strong {
        color:#8c8c8c;
    }
    

    /* ----- the footer ----- */

    footer {
        color:#8c8c8c;
        display:block;
        font-size:14px;
        line-height:28px;
        margin:0 0 80px 60px;
        width:600px;
    }

    footer nav {
        float:right;
    }

    /* ----- github ribbon ----- */

    .ribbon {
        border:0;
        position:absolute;
        right:0;
        top:0;
        z-index:100;
    }

    /* 
     *
     * Cleafloat: A Haiku
     * 
     * Markup zealots, please:
     * overflow:hidden is not
     * always an option.
     *
     */

    .clearfloat:after {
        display:block;
        visibility:hidden;
        clear:both;
        height:0;
        content:".";
    }
        
    .clearfloat {
        display:inline-block;
    }

    .clearfloat {
        display:block;
    }
    """,}
    return dict([(k, dedent(v).strip()) for k, v in templates.items()])

META_REGEX = re.compile(r"/(\d{4})\.(\d\d)\.(\d\d)\.(.+)")

if __name__ == "__main__":
    templates = get_templates()
    env = Environment(loader=DictLoader(templates))
    all_entries = read_and_parse_entries()
    shutil.copytree(DIRS['assets'], DIRS['build'])
    generate_index(all_entries, env.get_template('list.html'))
    os.mkdir(join(DIRS['build'], 'tags'))
    generate_tag_indices(all_entries, env.get_template('list.html'))
    generate_details(all_entries, env.get_template('detail.html'))
    generate_404(env.get_template('404.html'))
    generate_style(templates[STYLESHEET])
    shutil.rmtree(DIRS['public'])
    shutil.move(DIRS['build'], DIRS['public'])
