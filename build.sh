#!/bin/sh

rm -fr build
rm entries/*~ 2>/dev/null
python reprise.py &&
python httpd.py
