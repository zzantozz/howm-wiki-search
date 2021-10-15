#!/bin/bash -e

# Just produces a list of all the individual files that are the different entries/pages.

find ~/Dropbox/howm/ -type f -name '*.txt' -not -name 0000-00-00-000000.txt
