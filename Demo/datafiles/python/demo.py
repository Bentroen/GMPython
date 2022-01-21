import math
import random

print("Hello from Python!")

def get_bool():
	return random.choice([True, False])

def get_int():
	return random.randrange(100)

def get_float():
	return random.random()

def get_string():
	words = "The quick brown fox jumps over the lazy dog".split(" ")
	return random.choice(words)

def get_list():
	return list(range(10))
	
def get_dict():
	return dict(zip("abcdef", range(6)))

def get_a_lot_of_data():
	return "a" * 4096

def exception():
	print(2/0)

def sum(a, b):
	return a + b

def sqrt(x):
	return math.sqrt(x)

def reverse(s, upper=False):
	if upper:
		return s.upper()[::-1]
	else:
		return s[::-1]
