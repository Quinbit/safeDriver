from gpiozero import LED

start_pin = LED(12)
stop_pin = LED(26)


def stop_car():
    start_pin.off()

def start_car():
    start_pin.on()
