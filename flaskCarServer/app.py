import json
from flask import Flask, request

from gpio import GPIO


app = Flask(__name__)

distance_threshold = 0.2


@app.route('/')
def hello_world():
    return 'Hello, World!'


@app.route('/threshold', methods=['POST'])
def posts_threshold():
    distance_threshold = json.loads(list(request.form.to_dict().keys())[0])['stuff']
    print('Setting threshold to: ' + str(distance_threshold))
    return json.dumps({'success': True}), 200, {'ContentType': 'application/json'}


with GPIO() as gpio_interface:
    @app.route('/brake', methods=['POST', 'GET'])
    def brake():
        gpio_interface.brake()

    @app.route('/unbrake', methods=['POST', 'GET'])
    def unbrake():
        gpio_interface.unbrake()

    @app.route('/points', methods=['POST'])
    def post_points():
        distances = json.loads(list(request.form.to_dict().keys())[0])['stuff']

        distances.sort(reverse=True)

        closest_distance = distances[0] if len(distances) > 0 else None

        print('Closest distance is: ' + str(closest_distance))
        try:
            if closest_distance and closest_distance < distance_threshold:
                print('Braking')
                gpio_interface.brake()
            else:
                print('No brake')
                gpio_interface.unbrake()
            return json.dumps({'success': True}), 200, {'ContentType': 'application/json'}
        except Exception as e:
            if "Call was too frequent" in str(e):
                return json.dumps({'success': False}), 429, {'ContentType': 'application/json'}
            raise

if __name__ == "__main__":
    app.run("0.0.0.0", 8000)

