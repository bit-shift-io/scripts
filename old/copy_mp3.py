#!/usr/bin/env python
#-*- coding: utf-8 -*-

"""
A Python script to copy mp3 files from one directory to a
flat structure in another directory
Uses path.py module
"""

import os
import shutil
#from pathlib import path

DIRECTORY = '/home/s/Music/Music/'  # music source Directory
COPY_DIRECTORY = '/run/media/s/BRONSON/'  # Destination directory

d = os.path.abspath(DIRECTORY)
copy_directory = os.path.abspath(COPY_DIRECTORY)


def transfer():
    print("Copying Files from %s to %s" % (d, copy_directory))
    file_count = 0
    for root, dirs, files in os.walk(d):
        for file in files:
            if file.endswith('mp3'):
                file_count += 1
                print (file)
                src = root + '/' + file
                dst = copy_directory + '/' + file
                shutil.copyfile(src, dst)

    print ('Transferred %s files' % file_count)


if __name__ == "__main__":
    transfer()