import json
from flask import Flask, request
app = Flask(__name__)


@app.route('/')
def hello_world():
    return 'Hello, World!'


@app.route('/points', methods=['POST'])
def post_points():
    points = [(p[0], p[1], p[2]) for p in json.loads(list(request.form.to_dict().keys())[0])['stuff']]
    print(points)
    print(request.form.to_dict())
    return 'Done'
