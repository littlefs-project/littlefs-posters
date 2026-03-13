#!/usr/bin/env python3
#
# A local watch multitool
#

import base64
import glob
import hashlib
import itertools as it
import os
import shlex
import struct
import subprocess as sp
import sys
import threading as th
import time

try:
    import inotify_simple
except ModuleNotFoundError:
    inotify_simple = None

try:
    import http.server as http_server
except ModuleNotFoundError:
    http_server = None


# javascript blob for live-reloading
JS_LIVERELOAD = '''
<script>
    (function() {
        let ws = new WebSocket('ws://' +  window.location.host);
        ws.onopen = function() {
            ws.send('hello!');
            console.log('websocket connected');
        }
        ws.onmessage = function(message) {
            console.log('websocket recv', message.data);
            if (message.data == 'reload') {
                window.location.reload();
            }
        }
    })();
</script>
'''


# simple logging/errors with timestamps
def wristlog(level, message=None, **args):
    if message is None:
        level, message = 'info', level

    # ignore verbose unless requested
    if not args.get('verbose'):
        if level == 'verbose':
            return
        # ignore info if requested
        if args.get('quiet') and level == 'info':
            return

    # figure out what we should do for colors
    if args.get('color') == 'always':
        color = True
    elif args.get('color') == 'never':
        color = False
    else:
        color = sys.stdout.isatty()

    # log message
    now = time.time()
    print('%s[%s.%03d]%s ww: %s%s:%s %s' % (
                '\x1b[1;30m' if color else '',
                time.strftime('%H:%M:%S', time.localtime(now)),
                (now % 1)*1000,
                '\x1b[m' if color else '',
                '\x1b[1;30m' if color and level == 'verbose'
                    else '\x1b[1;33m' if color and level == 'warning'
                    else '\x1b[1;31m' if color and level == 'error'
                    else '',
                level,
                '\x1b[m' if color else '',
                message),
            file=(sys.stderr if level == 'error' else None))

def wristerror(level, message=None, code=1, **args):
    if message is None:
        level, message = 'error', level

    wristlog(level, message, **args)
    sys.exit(code)

# glob paths
def wristglob(paths, default=None, *,
        ignore=None,
        dereference=False):
    # default
    if paths is None:
        paths = default

    def glob_(paths):
        if isinstance(paths, str):
            paths = [paths]

        # expand globs
        paths_ = set()
        for path in paths:
            if '*' in path:
                for path_ in glob.iglob(path):
                    # normalize
                    path_ = os.path.relpath(path_)
                    paths_.add(path_)
            else:
                # normalize
                path_ = os.path.relpath(path)
                paths_.add(path_)
        paths = paths_

        return paths

    # expand paths
    paths = glob_(paths)

    # expand ignore paths
    if ignore is not None:
        ignore = glob_(ignore)
    else:
        ignore = set()

    # ignore ignore paths
    paths -= ignore

    # expand dirs recursively, unless they match an ignore path
    paths_ = paths
    while paths_:
        paths__ = set()
        for path in paths_:
            if os.path.isdir(path) and (
                    dereference or not os.path.islink(path)):
                paths__ |= glob_([os.path.join(path, '*')])

        # ignore ignore paths
        paths__ -= ignore
        # add to paths
        paths |= paths__
        # recurse
        paths_ = paths__

    return paths

# create inotify object for given path
def wristwatch(watch=None, ignore=None, **args):
    if inotify_simple is None:
        wristerror('inotify_simple module not found?', **args)

    # figure out paths
    watch_ = wristglob(watch, ['.'],
            ignore=ignore,
            dereference=args.get('dereference'))

    # create the inotify object
    inotify = inotify_simple.INotify()
    # interesting events
    flags = (inotify_simple.flags.ATTRIB
            | inotify_simple.flags.CREATE
            | inotify_simple.flags.DELETE
            | inotify_simple.flags.DELETE_SELF
            | inotify_simple.flags.MODIFY
            | inotify_simple.flags.MOVED_FROM
            | inotify_simple.flags.MOVED_TO
            | inotify_simple.flags.MOVE_SELF)

    # watch paths
    for path in sorted(watch_):
        try:
            inotify.add_watch(path, flags)
            wristlog('verbose', 'watching %s' % path, **args)
        # ignore missing paths
        except FileNotFoundError:
            pass

    return inotify

# run an optional command
def wristrun(command, **args):
    # subprocess does most of the work
    wristlog('info', 'running %s' % (
                ' '.join(shlex.quote(c) for c in command)),
            **args)
    try:
        p = sp.run(command)
        code = p.returncode
    # ignore missing paths
    except FileNotFoundError:
        code = -1

    if args.get('exit_on_error') and code != 0:
        wristerror('verbose', 'command failed with %d' % code,
                code=code,
                **args)

# host an optional webserver at a given address
def wristserve(addr, **args):
    if http_server is None:
        wristerror('http module not found?', **args)

    # spin up an http server

    # why is this so funky
    class Handler(http_server.SimpleHTTPRequestHandler):
        protocol_version = 'HTTP/1.1'

        def end_headers(self):
            self.send_header("Cache-Control", "no-cache")
            super().end_headers()

        def ws_handshake(self):
            # upgrade to websocket
            key = self.headers['Sec-WebSocket-Key']
            digest = str(base64.b64encode(
                    hashlib.sha1(
                            bytes(key, 'utf8')
                                + b"258EAFA5-E914-47DA-95CA-C5AB0DC85B11")
                        .digest()), 'utf8')
            self.send_response(101, 'Switching Protocols')
            self.send_header('Upgrade', 'websocket')
            self.send_header('Connection', 'Upgrade')
            self.send_header('Sec-WebSocket-Accept', digest)
            self.end_headers()

            wristlog('verbose', 'ws %d connected' % id(self),
                    **args)
            with httpd.lock:
                httpd.clients[id(self)] = self

            # spin
            try:
                while True:
                    # parse op, note BufferedIOBase is greedy
                    m_op = self.rfile.read(2)
                    m_len = m_op[1] & 0x7f
                    if m_len == 0x7e:
                        m_len, = struct.unpack('<H', self.rfile.read(2))
                    elif m_len == 0x7f:
                        m_len, = struct.unpack('<Q', self.rfile.read(8))
                    # parse mask
                    m_mask = b'\0\0\0\0'
                    if m_op[1] & 0x80:
                        m_mask = self.rfile.read(4)
                    # parse data
                    m_data = bytes(m ^ b for m, b in zip(
                            it.cycle(m_mask),
                            self.rfile.read(m_len)))

                    # recv
                    self.ws_recv(
                            m_op[0] & 0xf,
                            m_data.decode('utf8', errors='backslashreplace'))

                    # exit?
                    if m_op[0] & 0x08:
                        break
            # truncated message, ignore
            except IndexError:
                pass
            # disconnect
            finally:
                with httpd.lock:
                    del httpd.clients[id(self)]
                wristlog('verbose', 'ws %d disconnected' % id(self),
                        **args)

        def ws_recv(self, op, message):
            wristlog('verbose', 'ws %d recv 0x%x %s' % (
                        id(self), op, message),
                    **args)

        def ws_send(self, op, message=None):
            # op=0x81 => text message
            if message is None:
                op, message = 0x81, op

            with httpd.lock:
                # write op
                if len(message) <= 0x7d:
                    self.wfile.write(struct.pack('<BB',
                            0x80 | op, len(message)))
                elif len(message) <= 0xffff:
                    self.wfile.write(struct.pack('<BBH',
                            0x80 | op, 0x7e, len(message)))
                else:
                    self.wfile.write(struct.pack('<BBQ',
                            0x80 | op, 0x7f, len(message)))
                # write data
                if message:
                    self.wfile.write(bytes(message, 'utf8'))

            wristlog('verbose', 'ws %d send 0x%x %s' % (
                        id(self), op, message),
                    **args)

        def do_GET(self):
            # upgrade websocket?
            if self.headers.get('Upgrade') == 'websocket':
                self.ws_handshake()

            # livereload injection get?
            elif args.get('inject_livereload'):
                # convert to bytes
                payload = bytes(JS_LIVERELOAD.strip(), 'utf8')

                # intercept Content-Length
                is_html = False
                def send_header(self, key, value):
                    nonlocal is_html
                    if (key.lower() == 'content-type'
                            and value.split(';', 1)[0] == 'text/html'):
                        is_html = True
                    elif (key.lower() == 'content-length'
                            and is_html
                            and value != '0'):
                        value = str(int(value) + len(payload))
                    super().send_header(key, value)
                self.send_header = send_header.__get__(self)
                try:
                    super().do_GET()
                finally:
                    del self.send_header

                # inject payload
                if is_html:
                    self.wfile.write(payload)

            # normal get
            else:
                try:
                    super().do_GET()
                # ignore disconnected clients
                except BrokenPipeError:
                    pass

        def handle(self):
            try:
                super().handle()
            # ignore disconnected clients
            except ConnectionResetError:
                pass

        def log_message(self, fmt, *args_):
            wristlog('verbose', fmt % args_, **args)

    httpd = http_server.ThreadingHTTPServer(addr, Handler)
    # some shared state for websocket broadcasts
    httpd.lock = th.RLock()
    httpd.clients = {}
    def broadcast(self, op, message=None):
        with self.lock:
            for _, client in self.clients.items():
                client.ws_send(op, message)
    httpd.broadcast = broadcast.__get__(httpd)
    # run in a background thread
    httpd.thread = th.Thread(
            target=httpd.serve_forever,
            daemon=True)
    httpd.thread.start()

    wristlog('info', 'serving %s:%s' % (addr[0], addr[1]), **args)
    return httpd


# entry point
def main(command, *,
        watch=None,
        ignore=None,
        serve=None,
        **args):
    # just dump the livereload script?
    if args.get('help_livereload'):
        print(JS_LIVERELOAD.strip())
        sys.exit(0)

    httpd = None
    try:
        while True:
            # create inotify object _before_ running any commands, this
            # gives us the best chance to catch changes
            inotify = wristwatch(watch, ignore, **args)

            # run command, if any
            if command:
                wristrun(command, **args)

            if serve:
                # start http server after first successful run
                if httpd is None:
                    httpd = wristserve(serve, **args)
                # notify any waiting clients of changes
                httpd.broadcast('reload')

            # wait on inotify
            wristlog('verbose', 'wating...', **args)
            notifications = inotify.read()
            inotify.close()
            inotify = None
            wristlog('verbose', 'notified %s' % (notifications[0],), **args)

            # wait a bit to avoid flickering
            time.sleep(args.get('wait')
                    if args.get('wait') is not None
                    else 0.01)
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    import argparse
    import sys
    parser = argparse.ArgumentParser(
            description="A local watch multitool.",
            allow_abbrev=False)
    parser.add_argument(
            'command',
            nargs=argparse.REMAINDER,
            help="Optional command to run on changes.")
    parser.add_argument(
            '-v', '--verbose',
            action='store_true',
            help="Show more info.")
    parser.add_argument(
            '-q', '--quiet',
            action='store_true',
            help="Show less info.")
    parser.add_argument(
            '--color',
            choices=['never', 'always', 'auto'],
            default='auto',
            help="When to use terminal colors. Defaults to 'auto'.")
    parser.add_argument(
            '-K', '--watch',
            action='append',
            help="Paths to watch. Defaults to the current directory.")
    parser.add_argument(
            '-I', '--ignore',
            action='append',
            help="Paths to not watch.")
    parser.add_argument(
            '-L', '--dereference',
            action='store_true',
            help="Recurse into symlinks, which are ignored by default. Does "
                "not affect explicit paths. Watch out for cycles!")
    parser.add_argument(
            '-w', '--wait',
            type=float,
            help="Time to wait after changes. Defaults to 0.01 seconds.")
    parser.add_argument(
            '-s', '--serve', '--server',
            metavar='addr',
            type=lambda a: (lambda a, p: (a, int(p)))(*a.split(':', 1)),
            help="Run a simple http server at this address:port.")
    parser.add_argument(
            '--inject-livereload',
            action='store_true',
            help="Inject the live reload script into all .html and .htm "
                "files.")
    parser.add_argument(
            '--help-livereload',
            action='store_true',
            help="Print the live reload script in case you want to add this "
                "manually.")
    parser.add_argument(
            '-e', '--exit-on-error',
            action='store_true',
            help="Exit if command errors.")
    sys.exit(main(**{k: v
            for k, v in vars(parser.parse_args()).items()
            if v is not None}))
