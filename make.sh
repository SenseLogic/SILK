#!/bin/sh
set -x
dmd -m64 silk.d color.d png.d
rm *.o
