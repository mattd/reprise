import SimpleHTTPServer
import sys
import os

os.chdir('public')
try:
    SimpleHTTPServer.test()
except KeyboardInterrupt:
    print >>sys.stderr, " interrupted"
