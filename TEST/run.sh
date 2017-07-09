#!/bin/sh
set -x
../silk --smooth 1 9 128.0 --store --highlight 0.25 2.0 --posterize 3 1 tux.bmp OUT/tux_smooth_highlight_posterize.bmp
../silk --highlight 0.25 2.0 sea.bmp OUT/sea_highlight.bmp
../silk --smooth 1 9 128.0 mountain.bmp OUT/mountain_smooth.bmp
../silk --smooth 1 9 128.0 sea.bmp OUT/sea_smooth.bmp
../silk --smooth 1 9 128.0 tux.bmp OUT/tux_smooth.bmp
