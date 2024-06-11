/*
    This file is part of the Silk distribution.

    https://github.com/senselogic/SILK

    Copyright (C) 2017 Eric Pelzer (ecstatic.coder@gmail.com)

    Silk is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, version 3.

    Silk is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Silk.  If not, see <http://www.gnu.org/licenses/>.
*/

// -- IMPORTS

import arsd.color : Color, MemoryImage, TrueColorImage;
import arsd.png : readPng, writePng;
import core.stdc.stdlib : exit;
import std.algorithm : max, min;
import std.conv : to;
import std.file : read, write;
import std.math : sqrt;
import std.stdio : writeln;
import std.string : startsWith;

// -- TYPES

struct COLOR
{
    // -- ATTRIBUTES

    double
        Red = 0.0,
        Green = 0.0,
        Blue = 0.0;

    // -- INQUIRIES

    double GetDistance(
        ref COLOR color
        )
    {
        double
            blue_offset,
            green_offset,
            red_mean,
            red_offset,
            square_distance;

        red_mean = ( Red + color.Red ) * 0.5;
        red_offset = Red - color.Red;
        green_offset = Green - color.Green;
        blue_offset = Blue - color.Blue;

        square_distance
            = ( ( ( 512.0 + red_mean ) * red_offset * red_offset ) / 256.0 )
              + 4.0 * green_offset * green_offset
              + ( ( ( 767.0 - red_mean ) * blue_offset * blue_offset ) / 256.0 );

        return sqrt( square_distance );
    }

    // ~~

    double GetBrightnessContrastComponent(
        double component,
        double brightness_offset,
        double contrast_factor
        )
    {
        component = ( ( component / 255.0 - 0.5 ) * contrast_factor + 0.5 + brightness_offset ) * 255.0;

        return min( max( component, 0.0 ), 255.0 );
    }

    // -- OPERATIONS

    void Clear(
        )
    {
        Red = 0.0;
        Green = 0.0;
        Blue = 0.0;
    }

    // ~~

    void Set(
        double red = 0.0,
        double green = 0.0,
        double blue = 0.0
        )
    {
        Red = red;
        Green = green;
        Blue = blue;
    }

    // ~~

    void Add(
        ref COLOR color
        )
    {
        Red += color.Red;
        Green += color.Green;
        Blue += color.Blue;
    }

    // ~~

    void Divide(
        double divider
        )
    {
        Red /= divider;
        Green /= divider;
        Blue /= divider;
    }

    // ~~

    void Highlight(
        double brightness_offset,
        double contrast_factor
        )
    {
        Red = GetBrightnessContrastComponent( Red, brightness_offset, contrast_factor );
        Green = GetBrightnessContrastComponent( Green, brightness_offset, contrast_factor );
        Blue = GetBrightnessContrastComponent( Blue, brightness_offset, contrast_factor );
    }
}

// ~~

struct PAINT
{
    // -- ATTRIBUTES

    COLOR
        Color,
        AverageColor;
    long
        PixelCount;

    // -- OPERATIONS

    void Set(
        double red = 0.0,
        double green = 0.0,
        double blue = 0.0
        )
    {
        Color.Set( red, green, blue );

        AverageColor = Color;
    }

    // ~~

    void AddColor(
        ref COLOR color
        )
    {
        AverageColor.Add( color );

        ++PixelCount;
    }

    // ~~

    void SetAverageColor(
        )
    {
        if ( PixelCount > 0 )
        {
            AverageColor.Divide( PixelCount );
        }
        else
        {
            AverageColor = Color;
        }

        Color = AverageColor;
    }
}

// ~~

struct PIXEL
{
    // -- ATTRIBUTES

    COLOR
        Color,
        PriorColor,
        StoredColor;
    long
        PaintIndex;
}

// ~~

struct IMAGE
{
    // -- ATTRIBUTES

    ubyte[]
        ByteArray;
    long
        ColumnCount,
        LineCount;
    PIXEL[]
        PixelArray;
    PAINT[]
        PaintArray;

    // -- INQUIRIES

    long GetPixelIndex(
        long column_index,
        long line_index
        )
    {
        return line_index * ColumnCount + column_index;
    }

    // ~~

    long GetCheckedPixelIndex(
        long column_index,
        long line_index
        )
    {
        if ( column_index >= 0
             && column_index < ColumnCount
             && line_index >= 0
             && line_index < LineCount )
        {
            return line_index * ColumnCount + column_index;
        }
        else
        {
            return -1;
        }
    }

    // ~~

    long GetPaintIndex(
        ref COLOR color
        )
    {
        double
            best_color_distance,
            color_distance;
        long
            best_paint_index;

        best_paint_index = -1;
        best_color_distance = 0.0;

        foreach ( paint_index; 0 .. PaintArray.length )
        {
            color_distance = color.GetDistance( PaintArray[ paint_index ].Color );

            if ( best_paint_index < 0
                 || color_distance < best_color_distance )
            {
                best_paint_index = paint_index;
                best_color_distance = color_distance;
            }
        }

        return best_paint_index;
    }

    // -- OPERATIONS

    void ReadFile(
        string file_path
        )
    {
        long
            column_index,
            line_index,
            pixel_index;
        Color
            color;
        TrueColorImage
            true_color_image;
        COLOR
            pixel_color;

        writeln( "Reading file : ", file_path );

        true_color_image = readPng( file_path ).getAsTrueColorImage();

        LineCount = true_color_image.height();
        ColumnCount = true_color_image.width();
        PixelArray.length = LineCount * ColumnCount;

        for ( line_index = 0;
              line_index < LineCount;
              ++line_index )
        {
            for ( column_index = 0;
                  column_index < ColumnCount;
                  ++column_index )
            {
                color = true_color_image.getPixel( cast( int )column_index, cast( int )line_index );

                pixel_color.Red = color.r.to!double();
                pixel_color.Green = color.g.to!double();
                pixel_color.Blue = color.b.to!double();

                pixel_index = GetPixelIndex( column_index, line_index );
                PixelArray[ pixel_index ].Color = pixel_color;
                PixelArray[ pixel_index ].StoredColor = pixel_color;
            }
        }
    }

    // ~~

    void WriteFile(
        string file_path
        )
    {
        long
            column_index,
            line_index,
            pixel_index;
        Color
            color;
        TrueColorImage
            true_color_image;
        COLOR
            pixel_color;

        writeln( "Writing file : ", file_path );

        true_color_image = new TrueColorImage( cast( int )ColumnCount, cast( int )LineCount );

        for ( line_index = 0;
              line_index < LineCount;
              ++line_index )
        {
            for ( column_index = 0;
                  column_index < ColumnCount;
                  ++column_index )
            {
                pixel_index = GetPixelIndex( column_index, line_index );
                pixel_color = PixelArray[ pixel_index ].Color;

                color.r = pixel_color.Red.to!ubyte();
                color.g = pixel_color.Green.to!ubyte();
                color.b = pixel_color.Blue.to!ubyte();
                color.a = 255;

                true_color_image.setPixel( cast( int )column_index, cast( int )line_index, color );
            }
        }

        writePng( file_path, true_color_image );
    }

    // ~~

    void Store(
        )
    {
        writeln( "Storing image" );

        foreach ( ref pixel; PixelArray )
        {
            pixel.StoredColor = pixel.Color;
        }
    }

    // ~~

    void Highlight(
        double brightness_offset,
        double contrast_factor
        )
    {
        writeln( "Highlighting image : ", brightness_offset, " ", contrast_factor );

        foreach ( ref pixel; PixelArray )
        {
            pixel.Color.Highlight( brightness_offset, contrast_factor );
        }
    }

    // ~~

    void SetPriorColor(
        )
    {
        foreach ( ref pixel; PixelArray )
        {
            pixel.PriorColor = pixel.Color;
        }
    }

    // ~~

    void Smooth(
        long pass_count,
        long pixel_distance,
        double color_distance
        )
    {
        long
            other_pixel_index,
            pixel_count,
            pixel_index,
            radius;
        COLOR
            average_color,
            other_pixel_color,
            pixel_color;

        writeln( "Smoothing image : ", pass_count, " ", pixel_distance, " ", color_distance );

        foreach ( pass_index; 0 .. pass_count )
        {
            SetPriorColor();

            double md = 0.0;

            foreach ( line_index; 0 .. LineCount )
            {
                foreach ( column_index; 0 .. ColumnCount )
                {
                    pixel_index = GetPixelIndex( column_index, line_index );

                    pixel_color = PixelArray[ pixel_index ].PriorColor;
                    average_color.Clear();
                    pixel_count = 0;

                    foreach ( line_offset; -pixel_distance .. pixel_distance + 1 )
                    {
                        foreach ( column_offset; -pixel_distance .. pixel_distance + 1 )
                        {
                            other_pixel_index
                                = GetCheckedPixelIndex( column_index + column_offset, line_index + line_offset );

                            if ( other_pixel_index >= 0 )
                            {
                                other_pixel_color = PixelArray[ other_pixel_index ].PriorColor;

                                if ( other_pixel_color.GetDistance( pixel_color )
                                     < color_distance )
                                {
                                    average_color.Add( other_pixel_color );

                                    ++pixel_count;
                                }
                            }
                        }
                    }

                    if ( pixel_count > 1 )
                    {
                        average_color.Divide( pixel_count );

                        PixelArray[ pixel_index ].Color = average_color;
                    }
                }
            }
        }
    }

    // ~~

    void SetPaintArray(
        long component_count
        )
    {
        double[]
            component_array;
        PAINT
            paint;

        component_array.length = component_count;

        foreach ( component_index; 0 .. component_count )
        {
            component_array[ component_index ] = ( 255.0 * component_index ) / ( component_count - 1 );
        }

        foreach ( red; component_array )
        {
            foreach ( green; component_array )
            {
                foreach ( blue; component_array )
                {
                    paint.Set( red, green, blue );

                    PaintArray ~= paint;
                }
            }
        }
    }

    // ~~

    void Posterize(
        long component_count,
        long clustering_mode
        )
    {
        long
            pixel_index;
        PAINT
            black_paint,
            white_paint;

        writeln( "Posterizing image : ", component_count );

        SetPaintArray( component_count );

        if ( ( clustering_mode & 2 ) == 0 )
        {
            foreach ( ref paint; PaintArray )
            {
                paint.AverageColor.Clear();
                paint.PixelCount = 0;
            }

            foreach ( ref pixel; PixelArray )
            {
                pixel.PaintIndex = GetPaintIndex( pixel.Color );

                if ( ( clustering_mode & 1 ) == 0 )
                {
                    PaintArray[ pixel.PaintIndex ].AddColor( pixel.Color );
                }
                else
                {
                    PaintArray[ pixel.PaintIndex ].AddColor( pixel.StoredColor );
                }
            }

            foreach ( ref paint; PaintArray )
            {
                paint.SetAverageColor();
            }

            black_paint.Set( 0, 0, 0 );
            PaintArray ~= black_paint;

            white_paint.Set( 255, 255, 255 );
            PaintArray ~= white_paint;

            foreach ( line_index; 0 .. LineCount )
            {
                foreach ( column_index; 0 .. ColumnCount )
                {
                    pixel_index = GetPixelIndex( column_index, line_index );

                    if ( ( clustering_mode & 4 ) == 0
                         && PixelArray[ pixel_index ].PaintIndex != 0
                         && PixelArray[ pixel_index ].PaintIndex != PaintArray.length.to!long() - 3 )
                    {
                        PixelArray[ pixel_index ].Color
                            = PaintArray[ PixelArray[ pixel_index ].PaintIndex ].AverageColor;
                    }
                    else
                    {
                        PixelArray[ pixel_index ].Color
                            = PaintArray[ GetPaintIndex( PixelArray[ pixel_index ].Color ) ].AverageColor;
                    }
                }
            }
        }
        else
        {
            foreach ( line_index; 0 .. LineCount )
            {
                foreach ( column_index; 0 .. ColumnCount )
                {
                    pixel_index = GetPixelIndex( column_index, line_index );

                    PixelArray[ pixel_index ].Color
                        = PaintArray[ GetPaintIndex( PixelArray[ pixel_index ].Color ) ].Color;
                }
            }
        }
    }
}

// -- FUNCTIONS

void PrintError(
    string message
    )
{
    writeln( "*** ERROR : ", message );
}

// ~~

void Abort(
    string message
    )
{
    PrintError( message );

    exit( -1 );
}

// ~~

void main(
    string[] argument_array
    )
{
    string
        input_file_path,
        option,
        output_file_path;
    IMAGE
        image;

    argument_array = argument_array[ 1 .. $ ];

    if ( argument_array.length >= 2
         && !argument_array[ $ - 2 ].startsWith( "--" )
         && !argument_array[ $ - 1 ].startsWith( "--" ) )
    {
        input_file_path = argument_array[ $ - 2 ];
        output_file_path = argument_array[ $ - 1 ];

        argument_array = argument_array[ 0 .. $ - 2 ];

        image.ReadFile( input_file_path );

        while ( argument_array.length >= 1
                && argument_array[ 0 ].startsWith( "--" ) )
        {
            option = argument_array[ 0 ];

            argument_array = argument_array[ 1 .. $ ];

            if ( option == "--store" )
            {
                image.Store();
            }
            else if ( option == "--smooth"
                      && argument_array.length >= 3 )
            {
                image.Smooth(
                    argument_array[ 0 ].to!long(),
                    argument_array[ 1 ].to!long(),
                    argument_array[ 2 ].to!double()
                    );

                argument_array = argument_array[ 3 .. $ ];
            }
            else if ( option == "--highlight"
                      && argument_array.length >= 2 )
            {
                image.Highlight(
                    argument_array[ 0 ].to!double(),
                    argument_array[ 1 ].to!double()
                    );

                argument_array = argument_array[ 2 .. $ ];
            }
            else if ( option == "--posterize"
                      && argument_array.length >= 2 )
            {
                image.Posterize(
                    argument_array[ 0 ].to!long(),
                    argument_array[ 1 ].to!long()
                    );

                argument_array = argument_array[ 2 .. $ ];
            }
            else
            {
                Abort( "Invalid option : " ~ option );
            }
        }

        if ( argument_array.length >= 1 )
        {
            Abort( "Invalid option : " ~ argument_array[ 0 ] );
        }

        image.WriteFile( output_file_path );
    }
    else
    {
        writeln( "Usage :" );
        writeln( "    silk [options] input_file.png output_file.png" );
        writeln( "Options :" );
        writeln( "    --store" );
        writeln( "    --smooth pass_count pixel_distance color_distance" );
        writeln( "    --highlight brightness_offset contrast_factor" );
        writeln( "    --posterize color_component_count clustering_mode" );
        writeln( "Examples :" );
        writeln( "    silk --smooth 1 9 128.0 input.png output.png" );
        writeln( "    silk --highlight 0.25 2.0 input.png output.png" );
        writeln( "    silk --smooth 1 9 128.0 --store --highlight 0.25 2.0 --posterize 3 1 input.png output.png" );

        Abort( "Invalid arguments : " ~ argument_array.to!string() );
    }
}
