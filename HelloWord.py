import os
import random
import sys
from datetime import datetime

import requests

print("Hello")

# Fisrt comment

'''
Multi line comment`
------
This is my first python program

Types of variables in Python - 5
Numbers, Strings, List, Tuples, Dictionaries

Types of operations - 7 
+ - * / % ** //
'''

print("5 + 2 = ", 5+2)
print("5 - 2 = ", 5-2)
print("5 * 2 = ", 5*2)
print("5 / 2 = ", 5/2)
print("5 % 2 = ", 5 % 2)
print("5 ** 2 = ", 5**2)
print("5 // 2 = ", 5//2)

name = "Anil Varre"
dob = "07-11-1975"

languages = ["English", "Telugu", "Hindi", "Kannada", "Tamil"]
favorites = {"Food": "Chicken Biryani", "Dessert": "Kova",
             "Vacation": "Greece Islands", "Movie": "Predator"}

print(name)
print(dob)
print(languages)
print(favorites)

address1 = "48224 Heather Ct"
city = "Northville"
state = "MI"
country = "USA"

print("Address line 1 : {} \nCity : {} \nState : {} \nCountry : {}".format(
    address1, city, state, country))

for i in languages:
    print(i)

for i in favorites.keys():
    print("{} : {}".format(i, favorites.get(i)))


def calculateAge(bd):
    print("Calculating Age for DOB: {}".format(bd))
    dbcon = datetime.strptime(bd, "%m-%d-%Y")


calculateAge(dob)

r = requests.get('http://google.com')
print(r.status_code)
