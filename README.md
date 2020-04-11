[![Kritika Analysis Status](https://kritika.io/users/lancew/repos/9164114418542914/heads/master/status.svg)](https://kritika.io/users/lancew/repos/9164114418542914/heads/master/)

Simple script to create a Ical feed from IJF event on Judobase.

Install:
carton install

Execute:
carton exec perl ijf_ical.pl
or
carton exec perl ijf_ical.pl > ijf.ics

To simple use the feed, you use this url: https://raw.githubusercontent.com/lancew/ijf_ical/master/ijf.ics

To use the script that calculates the distances of the world tour renL

carton exec perl distance_calculator.pl
