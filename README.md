![](https://github.com/senselogic/SILK/blob/master/LOGO/silk.png)

# Silk

Simple image enhancer.

## Samples

![](https://github.com/senselogic/SILK/blob/master/SAMPLE/mountain.png)
![](https://github.com/senselogic/SILK/blob/master/SAMPLE/mountain_smooth.png)

![](https://github.com/senselogic/SILK/blob/master/SAMPLE/tux.png)
![](https://github.com/senselogic/SILK/blob/master/SAMPLE/tux_smooth.png)
![](https://github.com/senselogic/SILK/blob/master/SAMPLE/tux_smooth_highlight_posterize.png)

## Installation

Install the [DMD 2 compiler](https://dlang.org/download.html) (using the MinGW setup option on Windows).

Build the executable with the following command line :

```bash
dmd -m64 silk.d color.d png.d
```

## Command line

```bash
silk [options] input_file.png output_file.png
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
silk --smooth 1 9 128.0 input.png output.png
```

Smooth the image.

```bash
silk --highlight 0.25 2.0 input.png output.png
```

Highlight the image.

```bash
silk --smooth 1 9 128.0 --store --highlight 0.25 2.0 --posterize 3 1 input.png output.png
```

Smooth, highlight and posterize the image.

## Dependencies

*   [ARSD PNG library](https://github.com/adamdruppe/arsd)

## Limitations

Only supports RGB PNG files.

## Version

1.0

## Author

Eric Pelzer (ecstatic.coder@gmail.com).

## License

This project is licensed under the GNU General Public License version 3.

See the [LICENSE.md](LICENSE.md) file for details.
