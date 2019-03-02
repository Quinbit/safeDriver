import json
from flask import Flask, request
from math import sqrt
from statistics import mean

app = Flask(__name__)

count_threshold = 5
dist_threshold = 0.2
y_min = -1
y_max = 1


@app.route('/')
def hello_world():
    return 'Hello, World!'


@app.route('/points', methods=['POST'])
def post_points():
    points = [{'x': p[0], 'y': p[1], 'z': p[2]} for p in json.loads(list(request.form.to_dict().keys())[0])['stuff']]
    norms = [sqrt((p['x'] * p['x']) + (p['y'] * p['y']) + (p['z'] * p['z'])) for p in points]
    print(mean(norms))
    print('x: ' + str(mean(p['x'] for p in points)))
    print('y: ' + str(mean(p['y'] for p in points)))
    print('z: ' + str(mean(p['z'] for p in points)))

    return ''
