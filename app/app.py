#!/usr/bin/env python3

# app.py
#  - Check us out on Twitch at twitch.tv/SlimDevOps

from flask import Flask, jsonify

app = Flask(__name__)
app.config['DEBUG'] = True


@app.route('/')
def index():
    return jsonify({'msg': 'Success'})


@app.route('/hello')
def hello():
    return jsonify({'msg': 'Hello World!'})


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8008)
