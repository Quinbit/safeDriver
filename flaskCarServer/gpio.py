from gpiozero import LED

forward_pin = LED(36)  # high = forward; low = no forward
right_high = LED(12)
right_low = LED(13)
left_high = LED(69)
left_low = LED(115)


def brake():
    forward_pin.off()

def unbrake():
    forward_pin.on()


def turn_left():
    left_low.off()
    left_high.on()

    pass

def turn_right():
    pass
