from GPIOLibrary import GPIOProcessor
import time




class GPIO():
    def __init__(self):
        pass

    def __enter__(self):
        self.GP = GPIOProcessor()
        self.forward_pin = self.GP.getPin36()
        self.forward_pin.out()
        self.right_high = self.GP.getPin12()
        self.right_high.out()
        self.right_low = self.GP.getPin13()
        self.right_low.out()
        self.left_high = self.GP.getPin69()
        self.left_high.out()
        self.left_low = self.GP.getPin115()
        self.left_low.out()
        pass

    def __exit__(self, exc_type, exc_val, exc_tb):
        pass


    def brake(self):
        self.forward_pin.off()

    def unbrake(self):
        self.forward_pin.on()

    def turn_left(self):
        self.left_low.off()
        self.left_high.on()

    def turn_right(self):
        pass
