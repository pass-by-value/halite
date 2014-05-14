#!/usr/bin/env python

import bottle
import os
from bottle import request, Bottle, abort
# app = Bottle()


def loadApp(app):
    @app.route('/app/<path:path>')  # /app/<path>
    @app.route('/app/')  # /app/
    @app.route('/app')  # /app
    @app.route('/')  # /
    def appGet(path=''):
        print "Adi"
        print os.path.dirname(os.path.abspath(__file__))
        print "Adi"
        return bottle.static_file('my_html.html',
                                  os.path.dirname(os.path.abspath(__file__)))

    @app.route('/websocket')
    def handle_websocket():
        wsock = request.environ.get('wsgi.websocket')
        if not wsock:
            abort(400, 'Expected WebSocket request.')

        while True:
            try:
                message = wsock.receive()
                wsock.send("Your message was: %r" % message)
            except WebSocketError:
                break


def start():
    app = bottle.default_app()  # create bottle app
    loadApp(app)
    return app

import gevent
from gevent.pywsgi import WSGIServer
from geventwebsocket import WebSocketError
from geventwebsocket.handler import WebSocketHandler

if __name__ == '__main__':
    app = start()
    server = WSGIServer(("0.0.0.0", 8080), app,
                        handler_class=WebSocketHandler)
    server.serve_forever()
