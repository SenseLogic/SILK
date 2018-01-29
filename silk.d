/*
    This file is part of the Silk distribution.

    https://github.com/senselogic/REDRAW

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

// == LOCAL

// -- IMPORTS

import core.stdc.stdlib : exit;
import std.algorithm : max, min;
import std.conv : to;
import std.file : read, write;
import std.math : sqrt;
import std.stdio : writeln;
import std.string : startsWith;

// == GLOBAL

// -- TYPES

struct COLOR
{
    float
        Red,
        Green,
        Blue;

    // ~~

    void Clear(
        )
    {
        Red = 0.0f;
        Green = 0.0f;
        Blue = 0.0f;
    }

    // ~~

    void Set(
        float red = 0.0f,
        float green = 0.0f,
        float blue = 0.0f
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
        float divider
        )
    {
        Red /= divider;
        Green /= divider;
        Blue /= divider;
    }

    // ~~

    void SetFromNatural24(
        long natural
        )
    {
        Set(
            ( natural >> 16 ) & 255,
            ( natural >> 8 ) & 255,
            natural & 255
            );
    }

    // ~~

    long GetNatural24(
        )
    {
        return Blue.to!long() | ( Green.to!long() << 8 ) | ( Red.to!long() << 16 );
    }

    // ~~

    float GetDistance(
        ref COLOR color
        )
    {
        float
            blue_offset,
            green_offset,
            red_mean,
            red_offset,
            square_distance;

        red_mean = ( Red + color.Red ) * 0.5f;
        red_offset = Red - color.Red;
        green_offset = Green - color.Green;
        blue_offset = Blue - color.Blue;

        square_distance
            = ( ( ( 512.0f + red_mean ) * red_offset * red_offset ) / 256.0f )
              + 4.0f * green_offset * green_offset
              + ( ( ( 767.0f - red_mean ) * blue_offset * blue_offset ) / 256.0f );

        return sqrt( square_distance );
    }

    // ~~

    float GetBrightnessContrastComponent(
        float component,
        float brightness_offset,
        float contrast_factor
        )
    {
        component = ( ( component / 255.0f - 0.5f ) * contrast_factor + 0.5f + brightness_offset ) * 255.0f;

        return min( max( component, 0.0f ), 255.0f );
    }

    // ~~

    void Highlight(
        float brightness_offset,
        float contrast_factor
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
    COLOR
        Color,
        AverageColor;
    long
        PixelCount;

    // ~~

    void Set(
        float red = 0.0f,
        float green = 0.0f,
        float blue = 0.0f
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
    ubyte[]
        ByteArray;
    long
        LineCount,
        ColumnCount,
        PixelCount,
        PixelByteCount,
        LineByteCount,
        FirstByteIndex;
    PIXEL[]
        PixelArray;
    PAINT[]
        PaintArray;

    // ~~

    long GetNatural8(
        long byte_index
        )
    {
        return ByteArray[ byte_index ];
    }

    // ~~

    long GetNatural16(
        long byte_index
        )
    {
        return
            GetNatural8( byte_index )
            | ( GetNatural8( byte_index + 1 ) << 8 );
    }

    // ~~

    long GetNatural24(
        long byte_index
        )
    {
        return
            GetNatural8( byte_index )
            | ( GetNatural8( byte_index + 1 ) << 8 )
            | ( GetNatural8( byte_index + 2 ) << 16 );
    }

    // ~~

    long GetNatural32(
        long byte_index
        )
    {
        return
            GetNatural8( byte_index )
            | ( GetNatural8( byte_index + 1 ) << 8 )
            | ( GetNatural8( byte_index + 2 ) << 16 )
            | ( GetNatural8( byte_index + 3 ) << 24 );
    }

    // ~~

    void SetNatural24(
        long byte_index,
        long natural
        )
    {
        ByteArray[ byte_index ] = ( natural & 255 ).to!ubyte();
        ByteArray[ byte_index + 1 ] = ( ( natural >> 8 ) & 255 ).to!ubyte();
        ByteArray[ byte_index + 2 ] = ( ( natural >> 16 ) & 255 ).to!ubyte();
    }

    // ~~

    void ReadFile(
        string file_path
        )
    {
        writeln( "Reading file : ", file_path );

        ByteArray = cast( ubyte[] )file_path.read();

        if ( GetNatural8( 0 ) == 'B'
             && GetNatural8( 1 ) == 'M'
             && GetNatural32( 30 ) == 0 )
        {
            LineCount = GetNatural32( 22 );
            ColumnCount = GetNatural32( 18 );
            PixelCount = LineCount * ColumnCount;
            PixelByteCount = GetNatural16( 28 ) >> 3;
            LineByteCount = ( ( ColumnCount * PixelByteCount + 3 ) >> 2 ) << 2;
            FirstByteIndex = GetNatural32( 10 );
        }
        else
        {
            Abort( "Invalid file format" );
        }
    }

    // ~~

    void WriteFile(
        string file_path
        )
    {
        writeln( "Writing file : ", file_path );

        file_path.write( ByteArray );
    }

    // ~~

    long GetPixelIndex(
        long line_index,
        long column_index
        )
    {
        return line_index * ColumnCount + column_index;
    }

    // ~~

    long GetCheckedPixelIndex(
        long line_index,
        long column_index
        )
    {
        if ( line_index >= 0
             && line_index < LineCount
             && column_index >= 0
             && column_index < ColumnCount )
        {
            return line_index * ColumnCount + column_index;
        }
        else
        {
            return -1;
        }
    }

    // ~~

    long GetByteIndex(
        long line_index,
        long column_index
        )
    {
        return FirstByteIndex + line_index * LineByteCount + column_index * PixelByteCount;
    }

    // ~~

    void SetPixelArray(
        )
    {
        long
            byte_index,
            pixel_index;
        COLOR
            color;

        PixelArray = [];
        PixelArray.length = PixelCount;

        foreach ( line_index; 0 .. LineCount )
        {
            foreach ( column_index; 0 .. ColumnCount )
            {
                pixel_index = GetPixelIndex( line_index, column_index );
                byte_index = GetByteIndex( line_index, column_index );

                color.SetFromNatural24( GetNatural24( byte_index ) );

                PixelArray[ pixel_index ].Color = color;
                PixelArray[ pixel_index ].StoredColor = color;
            }
        }
    }

    // ~~

    void SetByteArray(
        )
    {
        long
            byte_index,
            pixel_index;

        foreach ( line_index; 0 .. LineCount )
        {
            foreach ( column_index; 0 .. ColumnCount )
            {
                pixel_index = line_index * ColumnCount + column_index;
                byte_index = FirstByteIndex + line_index * LineByteCount + column_index * PixelByteCount;

                SetNatural24( byte_index, PixelArray[ pixel_index ].Color.GetNatural24() );
            }
        }
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
        float brightness_offset,
        float contrast_factor
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
        float color_distance
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

            float md = 0.0;

            foreach ( line_index; 0 .. LineCount )
            {
                foreach ( column_index; 0 .. ColumnCount )
                {
                    pixel_index = GetPixelIndex( line_index, column_index );

                    pixel_color = PixelArray[ pixel_index ].PriorColor;
                    average_color.Clear();
                    pixel_count = 0;

                    foreach ( line_offset; -pixel_distance .. pixel_distance + 1 )
                    {
                        foreach ( column_offset; -pixel_distance .. pixel_distance + 1 )
                        {
                            other_pixel_index
                                = GetCheckedPixelIndex( line_index + line_offset, column_index + column_offset );

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
        float[]
            component_array;
        PAINT
            paint;

        component_array.length = component_count;

        foreach ( component_index; 0 .. component_count )
        {
            component_array[ component_index ] = ( 255.0f * component_index ) / ( component_count - 1 );
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

    long GetPaintIndex(
        ref COLOR color
        )
    {
        float
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
                    pixel_index = GetPixelIndex( line_index, column_index );

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
                    pixel_index = GetPixelIndex( line_index, column_index );

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
        image.SetPixelArray();

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
                    argument_array[ 2 ].to!float()
                    );

                argument_array = argument_array[ 3 .. $ ];
            }
            else if ( option == "--highlight"
                      && argument_array.length >= 2 )
            {
                image.Highlight(
                    argument_array[ 0 ].to!float(),
                    argument_array[ 1 ].to!float()
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

        image.SetByteArray();
        image.WriteFile( output_file_path );
    }
    else
    {
        writeln( "Usage :" );
        writeln( "    silk [options] input_file.bmp output_file.bmp" );
        writeln( "Options :" );
        writeln( "    --store" );
        writeln( "    --smooth pass_count pixel_distance color_distance" );
        writeln( "    --highlight brightness_offset contrast_factor" );
        writeln( "    --posterize color_component_count clustering_mode" );
        writeln( "Examples :" );
        writeln( "    silk --smooth 1 9 128.0 input.bmp output.bmp" );
        writeln( "    silk --highlight 0.25 2.0 input.bmp output.bmp" );
        writeln( "    silk --smooth 1 9 128.0 --store --highlight 0.25 2.0 --posterize 3 1 input.bmp output.bmp" );

        Abort( "Invalid arguments : " ~ argument_array.to!string() );
    }
}
