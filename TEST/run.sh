#!/bin/sh
set -x
../silk --smooth 1 9 128.0 --store --highlight 0.25 2.0 --posterize 3 1 tux.png OUT/tux_smooth_highlight_posterize.png
../silk --highlight 0.25 2.0 sea.png OUT/sea_highlight.png
../silk --smooth 1 9 128.0 mountain.png OUT/mountain_smooth.png
../silk --smooth 1 9 128.0 sea.png OUT/sea_smooth.png
../silk --smooth 1 9 128.0 tux.png OUT/tux_smooth.png
