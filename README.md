# Silk

Simple image enhancer.

## Samples

![](https://github.com/senselogic/SILK/blob/master/SAMPLE/mountain.png)
![](https://github.com/senselogic/SILK/blob/master/SAMPLE/mountain_smooth.png)

![](https://github.com/senselogic/SILK/blob/master/SAMPLE/sea.png)
![](https://github.com/senselogic/SILK/blob/master/SAMPLE/sea_smooth.png)
![](https://github.com/senselogic/SILK/blob/master/SAMPLE/sea_highlight.png)

![](https://github.com/senselogic/SILK/blob/master/SAMPLE/tux.png)
![](https://github.com/senselogic/SILK/blob/master/SAMPLE/tux_smooth.png)
![](https://github.com/senselogic/SILK/blob/master/SAMPLE/tux_smooth_highlight_posterize.png)

## Installation

Install the [DMD 2 compiler](https://dlang.org/download.html).

Build the executable with the following command line :

```bash
dmd -m64 silk.d
```

## Command line

```bash
silk [options] input_file.bmp output_file.bmp
```

### Options

```bash
--store
--smooth pass_count pixel_distance color_distance
--highlight brightness_offset contrast_factor
--posterize color_component_count clustering_mode
```

### Examples

```bash
silk --smooth 1 9 128.0 input.bmp output.bmp
```

Smooth the image.

```bash
silk --highlight 0.25 2.0 input.bmp output.bmp
```

Highlight the image.

```bash
silk --smooth 1 9 128.0 --store --highlight 0.25 2.0 --posterize 3 1 input.bmp output.bmp
```

Smooth, highlight and posterize the image.

## Limitations

Only supports uncompressed 24 bits BMP files.

## Version

0.1

## Author

Eric Pelzer (ecstatic.coder@gmail.com).

## License

This project is licensed under the GNU General Public License version 3.

See the [LICENSE.md](LICENSE.md) file for details.
