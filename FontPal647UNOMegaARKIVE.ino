/*
Project: ARDUINO FONT-PAL
Author: Alastair Roxburgh (aroxburgh@ieee.org) kiwiengr
Description: Font manager for Hitachi HD44780 LCD controllers

Version History:
2024-09-04  Initial creation 
2024-09-13  Updated Example 1: 'LCD scene'
2024-09-15  Updated Documentation and ReadMe 
2024-09-20  PROGMEM flash font bitmap storage for Arduino Mega (ATmega 2560).
2024-10-15  Added compiler preprocessor directives for CPU, LCD types.
2024-10-25  Timing tests and general tidy-up of comments.
2024-10-28  Added some simple support for custom tiling, with examples.
2025-02-17  Corrected the indexing of the vertical bargraph custom characters.  

= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = 

Copyright (c) 2024 Alastair Roxburgh
Font-Pal recreates the functionality of an original 68HC11 stack-frame
assembly language font manager named SCREENS, which was devised in 1997
by Alastair Roxburgh & Sunil Rawal for the EOS series of TheaterMaster
digital home theater audio processors. SCREENS parsed strings containing
simple 'mark down' font codes, arranged in a line below the actual text,
using strings literals, or dynamicslly constructed on-the-fly.

Written in Arduino C++, Font-Pal manages bitmapped LCD fonts stored in
arrays of struct, leveraging both the Arduino String class (similar to
C++ std::string) and char data types, as well as their respective methods.
This approach optimizes the brevity and clarity of the source code, while
maintaining latency at levels comparable or better than the response time
of typical transflective backlit LCD diplays based on the Hitachi HD44780
controller chip.

Dveloped expressly for the Arduino platform, although Font-Pal reproduces
most of the functionality of its 1977 68HC11 predecessor, its internal
algorithms are only remotely similar.

Font Pal currently works only with 2x20 LCD displays.  

Font Pal is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation version 3 or any later version of the License.

Font Pal is distributed in the hope that it will be useful, but WITHOUT
WITHOUT ANY WARRANTY; without even the implied warranty of MECHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Public License for more
details.

You should have received a copy of the GNU General Public License along
with Font Pal. If not, see <http://www.gnu.org/licenses/>.

See the license.txt file for further licensing & copyright details.
*/

//*********************** CONFIGURATION OPTIONS *************************** 

//=====[ARDUINO MODEL]========:
//#define CPU_MEGA
#define CPU_UNO_R4

//=====[LCD interface]========:
//#define LCD_INTERFACE_4BIT
#define LCD_INTERFACE_I2C

//=====[LCD size]=============:
//#define LCD_SIZE_16x2
//#define LCD_SIZE_20x2
#define LCD_SIZE_20x4


/****************************** TO DO *************************************
*  Study the feasibility of configuring Font Pal as an Arduino library.   
**************************************************************************/

#include <Arduino.h>

#ifdef CPU_MEGA
  #include <avr/pgmspace.h>
#endif

#ifdef LCD_INTERFACE_4BIT
  #include <LiquidCrystal.h> // by Arduino, Adafruit 1.0.7 (originally by Hans-Christoph Steiner)
                             // Not tested: PololuHD44780.h by pololu 2.0.0 (has 4-bit mode only) 
  LiquidCrystal lcd(7, 6, 8, 9, 10, 11, 12);  // RS, RW, E, D0, D1, D2, D3   
                                              // (7 parameters selects 4-bit read-write mode)
  #ifdef LCD_SIZE_16x2
    uint8_t screenLength = 64; // = 16 * 4 
  #elif defined(LCD_SIZE_20x2)
    uint8_t screenLength = 80; // = 20 * 4
  #elif defined(LCD_SIZE_20x4)
    uint8_t screenLength = 160; // = 20 * 8
  #endif
#endif

#ifdef LCD_INTERFACE_I2C
  #include <Wire.h>
  #include <LiquidCrystal_I2C.h> // by Frank de Brabander 1.1.2, (Parallel LCD equipped with PCF8574T I2C backpack).
  #ifdef LCD_SIZE_16x2
    LiquidCrystal_I2C lcd(0x27, 16, 2);  // I2C address, columns, rows
    uint8_t screenLength = 64; // = 16 * 4 
  #elif defined(LCD_SIZE_20x2)
    LiquidCrystal_I2C lcd(0x27, 20, 2);
    uint8_t screenLength = 80; // = 20 * 4
  #elif defined(LCD_SIZE_20x4)
    LiquidCrystal_I2C lcd(0x27, 20, 4);
    uint8_t screenLength = 160; // = 20 * 8
  #endif
#endif


// %%%%%%%%%%% GLOBALS:
String screenImage = ""; // Holds up to 80 fontChars (0-79) and fontFlags in an interleaved format (160 characters).
String lcdString = "";
uint8_t startPos = 0; // Position in screenImage that will be overwritten with a new font-formatted String.
String CC_id_table[8]; // e.g., {"gl","AB","",...}
uint8_t CGRAM_ptr; // Has values 0-7 to address the CC_id_table, but we must add 8 (gives 8-f) to address CGRAM!
byte blankBitmap[8] = {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00}; // All pixels off.
bool in_CC_id_table = false;

/*--------------------------------------------------------------------------*/
/*     A Collection of CC Strings for Digital Surround Sound Processors     */
/*--------------------------------------------------------------------------*/
String daisy[] = { "242|CCC" 
                   "1d1|CCC",          // 3/2/0 daisy 0  (daisies 0-6 are without LFE channel)

                   "2c2|CCC" 
                   "a5a|CCC",          // 2/P/0 daisy 1

                   "2c2|CCC" 
                   "ada|CCC",          // 2/0/0 daisy 2

                   "242|CCC" 
                   "a5a|CCC",          // 3/1/0 daisy 3

                   "242|CCC" 
                   "ada|CCC",          // 3/0/0 daisy 4

                   "2c2|CCC" 
                   "1d1|CCC",          // 2/2/0 daisy 5

                   "b4b|CCC" 
                   "ada|CCC",          // 1/0/0 daisy 6

                   "bcb|CCC" 
                   "ada|CCC",          // 0/0/0 daisy 7 (no lock pattern)

                   "232|CCC" 
                   "1e1|CCC",          // 3/2/.1 daisy 8 (daisy 8-14 are with LFE channel)

                   "2f2|CCC" 
                   "a6a|CCC",          // 2/P/.1 daisy 9 

                   "2f2|CCC" 
                   "aea|CCC",          // 2/0/.1 daisy 10

                   "232|CCC" 
                   "a6a|CCC",          // 3/1/.1 daisy 11

                   "232|CCC"  
                   "aea|CCC",          // 3/0/.1 daisy 12

                   "2f2|CCC" 
                   "1e1|CCC",          // 2/2/.1 daisy 13

                   "b3b|CCC"           // 1/0/.1 daisy 14
                   "aea|CCC",
                   
                   "242|CCC"           // 3/3/0  daisy 15 
                   "151|CCC",

                   "232|CCC"           // 3/3/.1 daisy 16 
                   "161|CCC",

                   "   |   "           // 0/0/0 daisy xx (for no lock mute) 
                   "   |   " 
                  };

String normalSpeakers[] = { "LF|cc",  // 0. E.g., Display a selectable menu of speakers (all are in small caps): LF  CR  RF  
                            "RF|cc",  // 1.                                                                      LS  SB  RS
                            "Ls|c ",  // 2.
                            "Rs|c ",  // 3.
                            "cR| c",  // 4.
                            "sB| c"   // 5.
                          };

String revSpeakers[] = {  "LF|VV",  // 0. Example of use: indicate a speaker selection for adjustment (all are in reverse small caps). 
                          "RF|VV",  // 1.
                          "Ls|VV",  // 2.
                          "Rs|VV",  // 3.
                          "cR|VV",  // 4.
                          "sB|VV"   // 5.
                        };

String HorizontalSPLmeter = {"SPL:  Ref!      . dB|"  // Boiler plate for horizontal SPL meter. Ref "!|G" (down arrow) marks a reference level.
                             "         G          "}; // However, the actual bar graph is constructed on the bottom LCD row (not shown)


/*---------------------------------------------------*/
/*     A Collection of Miscellaneous CC Strings      */
/*---------------------------------------------------*/
String NZ4logo = "NZ|LL"   // New Zealand logo inspired by Louise Kellerman's logo for the 10th Commonwealth Games, Christchurch, 1974).
                 "zn|LL";  // Use:  startPos = n; LCDfontManager(); setupRow123(); LCDfontManager();
                           // To center on the LCD, use n = 29 for a 20x4 LCD, n = 9 for a 20x2 LCD.


/* Waves of Alien Hordes for the Space Invaders Demo */
String invArray[][2] = {
                         { " a a a a a | I I I I I ", " a a a a a | O O O O O " }, // 0 Pairs of invader-swarm animation frames
                         { " b b b b b | I I I I I ", " b b b b b | O O O O O " }, // 1
                         { " c c c c c | I I I I I ", " c c c c c | O O O O O " }, // 2
                         { " d d d d d | I I I I I ", " d d d d d | O O O O O " }, // 3
                         { " e e e e e | I I I I I ", " e e e e e | O O O O O " }  // 4
                       };


/*--------------------------------------------*/
/*        CUSTOM 2x2 TILING PATTERNS          */
/* Tiles based on the 'T' (i.e., Tiling) font */
/*--------------------------------------------*/
String myTile[] = { "AB"
                    "CD", // myTile[0]

                    "EF"
                    "GH", // myTile[1]

                    "IJ"
                    "KL", // myTile[2]

                    "MN"
                    "OP", // myTile[3]

                    "QR"
                    "ST", // myTile[4]

                    "UV"
                    "WX", // myTile[5]

                    "uv"
                    "wx"  // myTile[6]
                  };


/*----------------------------------------------*/
/*            Custom Character Fonts            */
/*----------------------------------------------*/
// @@@@@@@@@@ G - BARGRAPH FONT @@@@@@@@@@
#ifdef CPU_MEGA
  //const 
#endif
byte bargraphfont[][8]  {  // "abcLR!876543210"
// Horizontal Bar Graph:
  { 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10 }, // 'a' one bar
  { 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14 }, // 'b' two bars
  { 0x15, 0x15, 0x15, 0x15, 0x15, 0x15, 0x15, 0x15 }, // 'c' three bars
  { 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18 }, // 'L' L-bar
  { 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03 }, // 'R' R-bar
  { 0x00, 0x1c, 0x04, 0x04, 0x04, 0x15, 0x0e, 0x04 }, // '!' bent down-arrow
// Multi-Channel VU Meter Verical Bar Graph (6 dB per step):
  { 0x1b, 0x1b, 0x1b, 0x1b, 0x1b, 0x1b, 0x1b, 0x1b }, // '8' = 48 dB, + 48 = 96 dB
  { 0x00, 0x1b, 0x1b, 0x1b, 0x1b, 0x1b, 0x1b, 0x1b }, // '7' = 42 dB, + 48 = 90 dB
  { 0x00, 0x00, 0x1b, 0x1b, 0x1b, 0x1b, 0x1b, 0x1b }, // '6' = 36 dB, + 48 = 84 dB
  { 0x00, 0x00, 0x00, 0x1b, 0x1b, 0x1b, 0x1b, 0x1b }, // '5' = 30 dB, + 48 = 78 dB 
  { 0x00, 0x00, 0x00, 0x00, 0x1b, 0x1b, 0x1b, 0x1b }, // '4' = 24 dB, + 48 = 72 dB
  { 0x00, 0x00, 0x00, 0x00, 0x00, 0x1b, 0x1b, 0x1b }, // '3' = 18 dB, + 48 = 66 dB
  { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1b, 0x1b }, // '2' = 12 dB, + 48 = 60 dB
  { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1b }, // '1' =  6 dB, + 48 = 54 dB
  { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }  // '0' no bar, -infinity dB
};

// @@@@@@@@@@ 0 to 9 - BIGNUMS FONTS @@@@@@@@@@
#ifdef CPU_MEGA
  //const 
#endif
byte big0font[][8]  {  // "ABCD"
// '0' = 4*0 + 0,1,2,3
  { 0x03, 0x07, 0x0f, 0x0e, 0x1c, 0x1c, 0x18, 0x18 }, // 'A'
  { 0x18, 0x1c, 0x1e, 0x0e, 0x07, 0x07, 0x03, 0x03 }, // 'B'
  { 0x18, 0x18, 0x1c, 0x1c, 0x0e, 0x0f, 0x07, 0x03 }, // 'C'
  { 0x03, 0x03, 0x07, 0x07, 0x0e, 0x1e, 0x1c, 0x18 }  // 'D'
};
#ifdef CPU_MEGA
  const 
#endif
byte big1font[][8]  {  // "ABCD"
// '1' = 4*1 + 0,1,2,3
  { 0x01, 0x07, 0x0f, 0x0f, 0x01, 0x01, 0x01, 0x01 }, // 'A'
  { 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10 }, // 'B'
  { 0x01, 0x01, 0x01, 0x01, 0x01, 0x0f, 0x0f, 0x0f }, // 'C'
  { 0x10, 0x10, 0x10, 0x10, 0x10, 0x1e, 0x1e, 0x1e }  // 'D'
};  
#ifdef CPU_MEGA
  const 
#endif
byte big2font[][8]  {  // "ABCD"
// '2' = 4*2 + 1
  { 0x01, 0x07, 0x0f, 0x1e, 0x18, 0x00, 0x00, 0x00 }, // 'A'
  { 0x18, 0x1c, 0x1e, 0x07, 0x03, 0x03, 0x07, 0x0e }, // 'B'
  { 0x00, 0x01, 0x03, 0x07, 0x0e, 0x1f, 0x1f, 0x1f }, // 'C'
  { 0x1c, 0x18, 0x10, 0x00, 0x03, 0x1f, 0x1f, 0x1f }  // 'D'
};  
#ifdef CPU_MEGA
  const 
#endif
byte big3font[][8]  {  // "ABCD"
// '3'
  { 0x03, 0x0f, 0x1f, 0x18, 0x00, 0x00, 0x00, 0x03 }, // 'A'
  { 0x18, 0x1c, 0x1e, 0x06, 0x06, 0x06, 0x0e, 0x1c }, // 'B'
  { 0x03, 0x00, 0x00, 0x10, 0x18, 0x1f, 0x0f, 0x07 }, // 'C'
  { 0x1e, 0x0f, 0x07, 0x07, 0x07, 0x1e, 0x1c, 0x18 }  // 'D'
};  
#ifdef CPU_MEGA
  const 
#endif
byte big4font[][8]  {  // "ABCD"
// '4'
  { 0x00, 0x00, 0x01, 0x01, 0x03, 0x03, 0x07, 0x0e }, // 'A'
  { 0x1c, 0x1c, 0x1c, 0x1c, 0x1c, 0x0c, 0x0c, 0x0c }, // 'B'
  { 0x1f, 0x1f, 0x1f, 0x00, 0x00, 0x00, 0x00, 0x00 }, // 'C'
  { 0x1f, 0x1f, 0x1f, 0x0c, 0x0c, 0x1e, 0x1e, 0x1e }  // 'D'
};  
#ifdef CPU_MEGA
  const 
#endif
byte big5font[][8]  {  // "ABCD"
// '5'
  { 0x0f, 0x0f, 0x0f, 0x0c, 0x0c, 0x0c, 0x0f, 0x0f }, // 'A'
  { 0x1f, 0x1f, 0x1f, 0x00, 0x00, 0x00, 0x1c, 0x1e }, // 'B'
  { 0x00, 0x00, 0x00, 0x08, 0x0c, 0x0f, 0x07, 0x03 }, // 'C'
  { 0x07, 0x03, 0x03, 0x03, 0x07, 0x1e, 0x1c, 0x18 }  // 'D'
};  
#ifdef CPU_MEGA
  const 
#endif
byte big6font[][8]  {  // "ABCD"
// '6'
  { 0x03, 0x07, 0x0e, 0x1c, 0x18, 0x18, 0x1b, 0x1f }, // 'A'
  { 0x1c, 0x1e, 0x07, 0x03, 0x01, 0x00, 0x1c, 0x1e }, // 'B'
  { 0x1c, 0x18, 0x18, 0x1c, 0x0e, 0x0f, 0x07, 0x03 }, // 'C'
  { 0x07, 0x03, 0x03, 0x03, 0x07, 0x1e, 0x1c, 0x18 }  // 'D'
};  
#ifdef CPU_MEGA
  const 
#endif
byte big7font[][8]  {  // "ABCD"
// '7'
  { 0x0f, 0x0f, 0x0f, 0x0c, 0x00, 0x00, 0x00, 0x00 }, // 'A'
  { 0x1f, 0x1f, 0x1f, 0x07, 0x07, 0x0e, 0x0e, 0x0e }, // 'B'
  { 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01 }, // 'C'
  { 0x1c, 0x18, 0x18, 0x18, 0x18, 0x10, 0x10, 0x10 }  // 'D'
};  
#ifdef CPU_MEGA
  const 
#endif
byte big8font[][8]  {  // "ABCD"
// '8'
  { 0x03, 0x07, 0x0f, 0x1c, 0x1c, 0x1c, 0x0e, 0x07 }, // 'A'
  { 0x18, 0x1c, 0x1e, 0x07, 0x07, 0x07, 0x0e, 0x1c }, // 'B'
  { 0x0f, 0x1c, 0x1c, 0x1c, 0x1c, 0x0f, 0x07, 0x03 }, // 'C'
  { 0x1e, 0x07, 0x07, 0x07, 0x07, 0x1e, 0x1c, 0x18 }  // 'D'
};  
#ifdef CPU_MEGA
  const 
#endif
byte big9font[][8]  {  // "ABCD"
// '9'
  { 0x03, 0x07, 0x0f, 0x1c, 0x18, 0x18, 0x18, 0x1c }, // 'A'
  { 0x18, 0x1c, 0x1e, 0x0e, 0x07, 0x03, 0x03, 0x07 }, // 'B'
  { 0x0f, 0x07, 0x00, 0x10, 0x18, 0x1c, 0x0f, 0x07 }, // 'C'
  { 0x1f, 0x1b, 0x03, 0x03, 0x07, 0x0e, 0x1c, 0x18 }  // 'D'
};

// @@@@@@@@@@ S - SYMBOL FONT @@@@@@@@@@
#ifdef CPU_MEGA
  const 
#endif
byte symbolfont[][8]  {  // "DSTMH><^vuds_1234KkLQnNbCFefghijcWXYZ"
  { 0x04, 0x04, 0x0a, 0x0a, 0x11, 0x11, 0x1f, 0x00 }, // 'D'   Greek Delta 
  { 0x1f, 0x10, 0x08, 0x04, 0x08, 0x10, 0x1f, 0x00 }, // 'S'   Greek Sigma 
  { 0x1f, 0x04, 0x04, 0x04, 0x00, 0x00, 0x00, 0x00 }, // 'T'   Trademark symbol, use "TM|SS"
  { 0x11, 0x1b, 0x15, 0x11, 0x00, 0x00, 0x00, 0x00 }, // 'M' 
  { 0x1b, 0x1f, 0x1b, 0x00, 0x1f, 0x18, 0x1e, 0x18 }, // 'H'   single HF character symbol, use "H|S"
  { 0x10, 0x18, 0x1c, 0x1e, 0x1c, 0x18, 0x10, 0x00 }, // '>'   Right Arrow symbol
  { 0x01, 0x03, 0x07, 0x0f, 0x07, 0x03, 0x01, 0x00 }, // '<'   Left Arrow symbol
  { 0x04, 0x04, 0x0e, 0x0e, 0x1f, 0x1f, 0x00, 0x00 }, // '^'   Up Arrow symbol
  { 0x00, 0x00, 0x1f, 0x1f, 0x0e, 0x0e, 0x04, 0x04 }, // 'v'   Down Arrow symbol
  { 0x04, 0x0e, 0x1f, 0x00, 0x04, 0x0e, 0x1f, 0x00 }, // 'u'   Up double arrow
  { 0x1f, 0x0e, 0x04, 0x00, 0x1f, 0x0e, 0x04, 0x00 }, // 'd'   Down double arrow
  { 0x00, 0x00, 0x00, 0x0e, 0x10, 0x0c, 0x02, 0x1c }, // 's'   Subscript 's' 
  { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f }, // '_'   underline char (in the cursor row)
  //
  { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00 }, // '1'   Centered 4-dot screen-saver pattern:
  { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10, 0x00 }, // '2'
  { 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // '3'
  { 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // '4'
  //
  { 0x00, 0x01, 0x03, 0x1f, 0x1f, 0x1f, 0x03, 0x01 }, // 'K'   Big Speaker (Kicker)
  { 0x00, 0x00, 0x01, 0x03, 0x0f, 0x03, 0x01, 0x00 }, // 'k'   small speaker (small-k kicker)
  { 0x00, 0x10, 0x18, 0x1f, 0x1f, 0x1f, 0x18, 0x10 }, // 'L'   Big Speaker reversed //fixed
  { 0x06, 0x08, 0x08, 0x1c, 0x08, 0x09, 0x16, 0x00 }, // 'Q'   Pound Sterling £ "Quid" (ALT-163)
  { 0x04, 0x06, 0x05, 0x05, 0x0c, 0x1c, 0x18, 0x00 }, // 'n'   Musical note
  { 0x06, 0x05, 0x07, 0x05, 0x05, 0x1d, 0x1b, 0x03 }, // 'N'   Two musical notes
  { 0x04, 0x0e, 0x0e, 0x0e, 0x1f, 0x04, 0x00, 0x00 }, // 'b'   Bell
  { 0x18, 0x18, 0x00, 0x07, 0x08, 0x08, 0x08, 0x07 }, // 'C'   Celsius degrees 
  { 0x18, 0x18, 0x00, 0x0f, 0x08, 0x0e, 0x08, 0x08 }, // 'F'   Fahrenheit degrees
  // 
  { 0x1f, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10 }, // 'e'   Frame LH top corner        efffffg 
  { 0x1f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // 'f'   Frame top                  c     h
  { 0x1f, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01 }, // 'g'   Frame RH top corner        j_____i
  { 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01 }, // 'h'   Frame RH side 
  { 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x1f }, // 'i'   Frame RH bottom corner 
  //                                                     '_'   Frame bottom (defined above)
  { 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x1f }, // 'j'   Frame LH bottom corner
  { 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10 }, // 'c'   Frame LH side
};

// @@@@@@@@@@ B - BOLD Uppercase FONT @@@@@@@@@@
#ifdef CPU_MEGA
  const 
#endif
byte Boldfont[][8]  { // "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  { 0x0e, 0x19, 0x19, 0x19, 0x1f, 0x19, 0x19, 0x00 }, // 'A'
  { 0x1e, 0x19, 0x19, 0x1e, 0x19, 0x19, 0x1e, 0x00 }, // 'B'
  { 0x0e, 0x19, 0x18, 0x18, 0x18, 0x19, 0x0e, 0x00 }, // 'C'
  { 0x1e, 0x19, 0x19, 0x19, 0x19, 0x19, 0x1e, 0x00 }, // 'D'
  { 0x1f, 0x18, 0x18, 0x1e, 0x18, 0x18, 0x1f, 0x00 }, // 'E'
  { 0x1f, 0x18, 0x18, 0x1e, 0x18, 0x18, 0x18, 0x00 }, // 'F' 
  { 0x0e, 0x19, 0x18, 0x1b, 0x19, 0x19, 0x0f, 0x00 }, // 'G'
  { 0x19, 0x19, 0x19, 0x1f, 0x19, 0x19, 0x19, 0x00 }, // 'H'
  { 0x0f, 0x06, 0x06, 0x06, 0x06, 0x06, 0x0f, 0x00 }, // 'I'
  { 0x0f, 0x06, 0x06, 0x06, 0x06, 0x16, 0x0c, 0x00 }, // 'J'
  { 0x1b, 0x1a, 0x1c, 0x18, 0x1c, 0x1a, 0x1b, 0x00 }, // 'K'
  { 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x1f, 0x00 }, // 'L'
  { 0x11, 0x1b, 0x1f, 0x1f, 0x1b, 0x1b, 0x1b, 0x00 }, // 'M'
  { 0x19, 0x19, 0x1d, 0x1f, 0x1b, 0x19, 0x19, 0x00 }, // 'N'
  { 0x0e, 0x19, 0x19, 0x19, 0x19, 0x19, 0x0e, 0x00 }, // 'O'
  { 0x1e, 0x19, 0x19, 0x19, 0x1e, 0x18, 0x18, 0x00 }, // 'P'
  { 0x0e, 0x19, 0x19, 0x19, 0x19, 0x1a, 0x0d, 0x00 }, // 'Q'
  { 0x1e, 0x19, 0x19, 0x1e, 0x1c, 0x1a, 0x1b, 0x00 }, // 'R'
  { 0x0e, 0x19, 0x1c, 0x0e, 0x07, 0x13, 0x0e, 0x00 }, // 'S'
  { 0x0f, 0x0f, 0x06, 0x06, 0x06, 0x06, 0x06, 0x00 }, // 'T'
  { 0x19, 0x19, 0x19, 0x19, 0x19, 0x19, 0x0e, 0x00 }, // 'U'
  { 0x19, 0x19, 0x19, 0x19, 0x19, 0x0a, 0x04, 0x00 }, // 'V'
  { 0x11, 0x11, 0x11, 0x15, 0x1f, 0x1f, 0x0a, 0x00 }, // 'W'
  { 0x19, 0x19, 0x0e, 0x04, 0x0e, 0x13, 0x13, 0x00 }, // 'X'
  { 0x19, 0x19, 0x19, 0x0e, 0x04, 0x04, 0x0e, 0x00 }, // 'Y'
//{ 0x1f, 0x03, 0x02, 0x04, 0x08, 0x18, 0x1f, 0x00 }, // 'Z'
  { 0x1f, 0x03, 0x06, 0x0c, 0x18, 0x18, 0x1f, 0x00 }, // 'Z' revised
  { 0x0e, 0x19, 0x19, 0x19, 0x19, 0x19, 0x0e, 0x00 }, // '0'
  { 0x06, 0x0e, 0x16, 0x06, 0x06, 0x06, 0x1f, 0x00 }, // '1'
  { 0x0e, 0x13, 0x03, 0x06, 0x0c, 0x18, 0x1f, 0x00 }, // '2'
  { 0x1f, 0x03, 0x06, 0x0e, 0x03, 0x13, 0x0e, 0x00 }, // '3'
  { 0x06, 0x0e, 0x16, 0x16, 0x1f, 0x06, 0x06, 0x00 }, // '4'
  { 0x1f, 0x18, 0x18, 0x1e, 0x01, 0x11, 0x1e, 0x00 }, // '5'
  { 0x07, 0x0c, 0x18, 0x1e, 0x19, 0x19, 0x0e, 0x00 }, // '6'
  { 0x1f, 0x13, 0x03, 0x06, 0x0c, 0x0c, 0x0c, 0x00 }, // '7'
  { 0x0e, 0x19, 0x19, 0x0e, 0x19, 0x19, 0x0e, 0x00 }, // '8'
  { 0x0e, 0x19, 0x19, 0x0f, 0x01, 0x02, 0x0c, 0x00 }  // '9'
};

// @@@@@@@@@@ b - bold Lowercase Font @@@@@@@@@@
#ifdef CPU_MEGA
  const 
#endif
byte boldlcfont[][8]  { // "abcdefghijklmnopqrstuvwxyz"
  { 0x00, 0x00, 0x0e, 0x03, 0x0f, 0x1b, 0x0f, 0x00 }, // 'a'
  { 0x18, 0x18, 0x1e, 0x1b, 0x1b, 0x1b, 0x1e, 0x00 }, // 'b'
  { 0x00, 0x00, 0x0e, 0x1b, 0x18, 0x1b, 0x0e, 0x00 }, // 'c' 
  { 0x03, 0x03, 0x0f, 0x1b, 0x1b, 0x1b, 0x0f, 0x00 }, // 'd'
  { 0x00, 0x00, 0x0e, 0x1b, 0x1f, 0x18, 0x0e, 0x00 }, // 'e'
  { 0x06, 0x0d, 0x0c, 0x1e, 0x0c, 0x0c, 0x0c, 0x00 }, // 'f'
  { 0x00, 0x00, 0x0f, 0x1b, 0x1b, 0x0f, 0x03, 0x0e }, // 'g'
  { 0x18, 0x18, 0x1e, 0x1b, 0x1b, 0x1b, 0x1b, 0x00 }, // 'h'
  { 0x06, 0x00, 0x0e, 0x06, 0x06, 0x06, 0x0f, 0x00 }, // 'i'
  { 0x03, 0x00, 0x07, 0x03, 0x03, 0x03, 0x13, 0x0e }, // 'j'
  { 0x18, 0x18, 0x1b, 0x1e, 0x1c, 0x1a, 0x1b, 0x00 }, // 'k'
  { 0x0e, 0x06, 0x06, 0x06, 0x06, 0x06, 0x0f, 0x00 }, // 'l'
  { 0x00, 0x00, 0x1a, 0x1f, 0x15, 0x15, 0x15, 0x00 }, // 'm'
  { 0x00, 0x00, 0x16, 0x1b, 0x1b, 0x1b, 0x1b, 0x00 }, // 'n'
  { 0x00, 0x00, 0x0e, 0x1b, 0x1b, 0x1b, 0x0e, 0x00 }, // 'o'
  { 0x00, 0x00, 0x1e, 0x1b, 0x1b, 0x1e, 0x18, 0x18 }, // 'p'
  { 0x00, 0x00, 0x0d, 0x13, 0x13, 0x0f, 0x03, 0x03 }, // 'q'
  { 0x00, 0x00, 0x16, 0x19, 0x18, 0x18, 0x18, 0x00 }, // 'r'
  { 0x00, 0x00, 0x0f, 0x1c, 0x0e, 0x07, 0x1e, 0x00 }, // 's'
  { 0x0c, 0x0c, 0x1e, 0x0c, 0x0c, 0x0d, 0x06, 0x00 }, // 't'
  { 0x00, 0x00, 0x1b, 0x1b, 0x1b, 0x1b, 0x0d, 0x00 }, // 'u'
  { 0x00, 0x00, 0x1b, 0x1b, 0x1b, 0x0a, 0x04, 0x00 }, // 'v'
  { 0x00, 0x00, 0x11, 0x15, 0x1f, 0x1b, 0x11, 0x00 }, // 'w'
  { 0x00, 0x00, 0x11, 0x1b, 0x0e, 0x1b, 0x11, 0x00 }, // 'x'
  { 0x00, 0x00, 0x1b, 0x1b, 0x1b, 0x0f, 0x03, 0x0e }, // 'y'
  { 0x00, 0x00, 0x1f, 0x03, 0x06, 0x0c, 0x1f, 0x00 }  // 'z'
};

// %%%%%%%%%% l - LOWERCASE FONT %%%%%%%%%%
#ifdef CPU_MEGA
  const 
#endif
byte lowercasefont[][8]  { // "gjpqym"
  { 0x00, 0x00, 0x0f, 0x11, 0x11, 0x0f, 0x01, 0x0e }, // 'g' 
  { 0x02, 0x00, 0x06, 0x02, 0x02, 0x02, 0x12, 0x0c }, // 'j'
  { 0x00, 0x00, 0x1e, 0x11, 0x11, 0x1e, 0x10, 0x10 }, // 'p'
  { 0x00, 0x00, 0x0e, 0x12, 0x12, 0x0e, 0x02, 0x03 }, // 'q'
  { 0x00, 0x00, 0x11, 0x11, 0x11, 0x0f, 0x01, 0x0e }, // 'y'
  { 0x00, 0x00, 0x1a, 0x15, 0x15, 0x15, 0x15, 0x00 }  // 'm'  An alternate to the ROM 'm'
};

// @@@@@@@@@@ c - SMALL CAPS FONT @@@@@@@@@@
#ifdef CPU_MEGA
  const 
#endif
byte smallcapsfont[][8]  { // "ABDEFGHIJKLMNPQRTUY"
  { 0x00, 0x00, 0x0e, 0x11, 0x1f, 0x11, 0x11, 0x00 }, // 'A'
  { 0x00, 0x00, 0x1e, 0x11, 0x1e, 0x11, 0x1e, 0x00 }, // 'B'
// Use c
  { 0x00, 0x00, 0x1e, 0x11, 0x11, 0x11, 0x1e, 0x00 }, // 'D'
  { 0x00, 0x00, 0x1f, 0x10, 0x1c, 0x10, 0x1f, 0x00 }, // 'E'
  { 0x00, 0x00, 0x1f, 0x10, 0x1c, 0x10, 0x10, 0x00 }, // 'F'
  { 0x00, 0x00, 0x0f, 0x10, 0x17, 0x11, 0x0f, 0x00 }, // 'G'
  { 0x00, 0x00, 0x11, 0x11, 0x1f, 0x11, 0x11, 0x00 }, // 'H'
  { 0x00, 0x00, 0x0e, 0x04, 0x04, 0x04, 0x0e, 0x00 }, // 'I'
  { 0x00, 0x00, 0x01, 0x01, 0x01, 0x11, 0x0e, 0x00 }, // 'J'
  { 0x00, 0x00, 0x12, 0x14, 0x18, 0x14, 0x12, 0x00 }, // 'K'
  { 0x00, 0x00, 0x10, 0x10, 0x10, 0x10, 0x1f, 0x00 }, // 'L'
  { 0x00, 0x00, 0x11, 0x1b, 0x15, 0x11, 0x11, 0x00 }, // 'M'
  { 0x00, 0x00, 0x11, 0x19, 0x15, 0x13, 0x11, 0x00 }, // 'N'
// Use o
  { 0x00, 0x00, 0x1e, 0x11, 0x1e, 0x10, 0x10, 0x00 }, // 'P'
  { 0x00, 0x00, 0x0e, 0x11, 0x11, 0x15, 0x0e, 0x01 }, // 'Q'
  { 0x00, 0x00, 0x1e, 0x11, 0x1e, 0x14, 0x12, 0x00 }, // 'R'
// Use s
  { 0x00, 0x00, 0x1f, 0x04, 0x04, 0x04, 0x04, 0x00 }, // 'T'
  { 0x00, 0x00, 0x11, 0x11, 0x11, 0x11, 0x0e, 0x00 }, // 'U'
// Use v
// Use w
// Use x
  { 0x00, 0x00, 0x11, 0x11, 0x0a, 0x04, 0x04, 0x00 }  // 'Y'
// Use z
};

// @@@@@@@@@@ f - SMALL FREQUENCY FONT @@@@@@@@@@
#ifdef CPU_MEGA
  const 
#endif
byte smlfrequfont[][8]  { // "kHz"
  { 0x00, 0x00, 0x08, 0x0a, 0x0c, 0x0a, 0x09, 0x00 }, // 'k' as in kHz
  { 0x00, 0x00, 0x09, 0x09, 0x0f, 0x09, 0x09, 0x00 }, // 'H' as in Hz
  { 0x00, 0x00, 0x00, 0x1e, 0x04, 0x08, 0x1e, 0x00 }  // 'z' as in Hz
};

// @@@@@@@@@@ v - SMALL REVERSE CAPS FONT @@@@@@@@@@
#ifdef CPU_MEGA
  const 
#endif
byte smlrevcapsfont[][8]  { // "BCFLSTR"
  { 0x1f, 0x1f, 0x13, 0x15, 0x13, 0x15, 0x13, 0x1f }, // 'B'
  { 0x1f, 0x1f, 0x19, 0x17, 0x17, 0x17, 0x19, 0x1f }, // 'C'
  { 0x1f, 0x1f, 0x11, 0x17, 0x11, 0x17, 0x17, 0x1f }, // 'F'
  { 0x1f, 0x1f, 0x17, 0x17, 0x17, 0x17, 0x11, 0x1f }, // 'L'
  { 0x1f, 0x1f, 0x19, 0x17, 0x1b, 0x1d, 0x13, 0x1f }, // 'S'
  { 0x1f, 0x1f, 0x11, 0x1b, 0x1b, 0x1b, 0x1b, 0x1f }, // 'T'
  { 0x1f, 0x1f, 0x13, 0x15, 0x13, 0x15, 0x15, 0x1f }  // 'R'
};

// @@@@@@@@@@ V - REVERSE CAPS FONT @@@@@@@@@@
#ifdef CPU_MEGA
  const 
#endif
byte revcapsfont[][8]  { // "ABCDEFGHIKLOPRSTUVXYZ0123456789=:"
  { 0x1f, 0x1b, 0x15, 0x15, 0x11, 0x15, 0x15, 0x1f }, // 'A'
  { 0x1f, 0x13, 0x15, 0x13, 0x15, 0x15, 0x13, 0x1f }, // 'B'
  { 0x1f, 0x19, 0x17, 0x17, 0x17, 0x17, 0x19, 0x1f }, // 'C'
  { 0x1f, 0x13, 0x15, 0x15, 0x15, 0x15, 0x13, 0x1f }, // 'D'
  { 0x1f, 0x11, 0x17, 0x11, 0x17, 0x17, 0x11, 0x1f }, // 'E'
  { 0x1f, 0x11, 0x17, 0x13, 0x17, 0x17, 0x17, 0x1f }, // 'F'
  { 0x1f, 0x11, 0x17, 0x17, 0x15, 0x15, 0x11, 0x1f }, // 'G'
  { 0x1f, 0x15, 0x15, 0x11, 0x15, 0x15, 0x15, 0x1f }, // 'H'
  { 0x1f, 0x11, 0x1b, 0x1b, 0x1b, 0x1b, 0x11, 0x1f }, // 'I'
// No J 
  { 0x1f, 0x15, 0x13, 0x17, 0x13, 0x15, 0x15, 0x1f }, // 'K'
  { 0x1f, 0x17, 0x17, 0x17, 0x17, 0x17, 0x11, 0x1f }, // 'L'
// No M,N
  { 0x1f, 0x11, 0x15, 0x15, 0x15, 0x15, 0x11, 0x1f }, // 'O'
  { 0x1f, 0x13, 0x15, 0x15, 0x13, 0x17, 0x17, 0x1f }, // 'P'
// No Q
  { 0x1f, 0x11, 0x15, 0x11, 0x13, 0x15, 0x15, 0x1f }, // 'R'
  { 0x1f, 0x19, 0x17, 0x1b, 0x1d, 0x1d, 0x13, 0x1f }, // 'S'
  { 0x1f, 0x11, 0x1b, 0x1b, 0x1b, 0x1b, 0x1b, 0x1f }, // 'T'
  { 0x1f, 0x15, 0x15, 0x15, 0x15, 0x15, 0x11, 0x1f }, // 'U'
  { 0x1f, 0x15, 0x15, 0x15, 0x15, 0x15, 0x1b, 0x1f }, // 'V'
// No W
  { 0x1f, 0x15, 0x15, 0x1b, 0x1b, 0x15, 0x15, 0x1f }, // 'X'
  { 0x1f, 0x15, 0x15, 0x1b, 0x1b, 0x1b, 0x1b, 0x1f }, // 'Y'
  { 0x1f, 0x11, 0x1d, 0x1b, 0x1b, 0x17, 0x11, 0x1f }, // 'Z'
  { 0x1f, 0x1b, 0x15, 0x15, 0x15, 0x15, 0x1b, 0x1f }, // '0'
  { 0x1f, 0x1b, 0x13, 0x1b, 0x1b, 0x1b, 0x11, 0x1f }, // '1'
  { 0x1f, 0x1b, 0x15, 0x1d, 0x1b, 0x17, 0x11, 0x1f }, // '2'
  { 0x1f, 0x11, 0x1d, 0x1b, 0x1d, 0x15, 0x1b, 0x1f }, // '3'
  { 0x1f, 0x17, 0x15, 0x15, 0x11, 0x1d, 0x1d, 0x1f }, // '4'
  { 0x1f, 0x11, 0x17, 0x1b, 0x1d, 0x15, 0x1b, 0x1f }, // '5'
  { 0x1f, 0x1b, 0x15, 0x17, 0x13, 0x15, 0x1b, 0x1f }, // '6'
  { 0x1f, 0x11, 0x15, 0x1d, 0x1b, 0x17, 0x17, 0x1f }, // '7'
  { 0x1f, 0x11, 0x15, 0x1b, 0x15, 0x15, 0x11, 0x1f }, // '8' thin waist, 1b is rounded top and bottom
  { 0x1f, 0x1b, 0x15, 0x19, 0x1d, 0x15, 0x1b, 0x1f }, // '9'
  { 0x1f, 0x1f, 0x1f, 0x1f, 0x1f, 0x1f, 0x1f, 0x1f }, // '=' space (5x8 black pixels)
  { 0x1f, 0x1f, 0x1f, 0x1b, 0x1f, 0x1b, 0x1f, 0x1f }  // ':' colon
};

// @@@@@@@@@@ C - CHANNEL-DAISY FONT @@@@@@@@@@
#ifdef CPU_MEGA
  const 
#endif
byte channelfont[][8]  { // "241dca5b3ef6xyzuvwjkl"
                           
  { 0x00, 0x00, 0x00, 0x0e, 0x1f, 0x1f, 0x1f, 0x0e }, // '2'
  { 0x0e, 0x1f, 0x1f, 0x1f, 0x0e, 0x00, 0x0e, 0x11 }, // '4'
  { 0x0e, 0x1f, 0x1f, 0x1f, 0x0e, 0x00, 0x00, 0x00 }, // '1'
  { 0x11, 0x0e, 0x00, 0x0e, 0x11, 0x11, 0x11, 0x0e }, // 'd'
  //=================================================
  { 0x0e, 0x11, 0x11, 0x11, 0x0e, 0x00, 0x0e, 0x11 }, // 'c'
  { 0x0e, 0x11, 0x11, 0x11, 0x0e, 0x00, 0x00, 0x00 }, // 'a'
  { 0x11, 0x0e, 0x00, 0x0e, 0x1f, 0x1f, 0x1f, 0x0e }, // '5'
  //=================================================
  { 0x00, 0x00, 0x00, 0x0e, 0x11, 0x11, 0x11, 0x0e }, // 'b'
  //=================================================
  { 0x0e, 0x1f, 0x1f, 0x1f, 0x0e, 0x00, 0x0e, 0x1f }, // '3'
  { 0x1f, 0x0e, 0x00, 0x0e, 0x11, 0x11, 0x11, 0x0e }, // 'e'
  //=================================================
  { 0x0e, 0x11, 0x11, 0x11, 0x0e, 0x00, 0x0e, 0x1f }, // 'f'
  { 0x1f, 0x0e, 0x00, 0x0e, 0x1f, 0x1f, 0x1f, 0x0e }, // '6'
  //=================================================
  { 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x05, 0x00 }, // 'x' Analog pass-thru lower-half of daisy (vertical triangle) "xyz|CCC"
  { 0x04, 0x04, 0x15, 0x15, 0x15, 0x15, 0x15, 0x00 }, // 'y'
  { 0x00, 0x00, 0x00, 0x00, 0x10, 0x10, 0x14, 0x00 }, // 'z'
  //=================================================
  { 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x07, 0x00 }, // 'u' Analog pass-thru 'Mute' daisy (hor. triangle) "uvw|CCC" (alternate with xyz|CCC)
  { 0x04, 0x00, 0x1f, 0x00, 0x1f, 0x00, 0x1f, 0x00 }, // 'v'
  { 0x00, 0x00, 0x00, 0x00, 0x10, 0x00, 0x1c, 0x00 }, // 'w'
  //=================================================
  { 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x00 }, // 'j' Solid triangle symbol (same shape as the vert,. and hor. triangles) "jkl|CCC"
  { 0x04, 0x0e, 0x1f, 0x1f, 0x1f, 0x1f, 0x1f, 0x00 }, // 'k'
  { 0x00, 0x00, 0x00, 0x00, 0x10, 0x18, 0x1c, 0x00 }  // 'l'

};

// @@@@@@@@@@ L - LOGOS FONT @@@@@@@@@@
#ifdef CPU_MEGA
  const 
#endif
byte logofont[][8]  { // "LRdtsHDC0123456nNzZ"
  { 0x1f, 0x13, 0x11, 0x11, 0x11, 0x13, 0x1f, 0x00 }, // 'L'    (Dolby Labs logo, use "LR|LL")
  { 0x1f, 0x19, 0x11, 0x11, 0x11, 0x19, 0x1f, 0x00 }, // 'R'
//
  { 0x03, 0x03, 0x03, 0x0f, 0x1b, 0x1b, 0x0f, 0x00 }, // 'd'    (Digital Theater Systems logo. use "dts|LLL")
  { 0x04, 0x0c, 0x1f, 0x0c, 0x0c, 0x0c, 0x07, 0x00 }, // 't'
  { 0x00, 0x00, 0x0f, 0x1c, 0x0e, 0x07, 0x1c, 0x00 }, // 's'
//
  { 0x00, 0x00, 0x11, 0x11, 0x1f, 0x11, 0x11, 0x00 }, // 'H'    ('HDCD' small caps logo, use "HDCD|LLLL")
  { 0x00, 0x00, 0x1e, 0x11, 0x11, 0x11, 0x1e, 0x00 }, // 'D'
  { 0x00, 0x00, 0x0f, 0x10, 0x10, 0x10, 0x0f, 0x00 }, // 'C'
//
// Standard version of CinEQ: Use "0123456"
  { 0x00, 0x00, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00 }, // '0' _  ('-cinEQ--' EAD CinEQ logo, use "0123456|LLLLLLL")
  { 0x03, 0x04, 0x04, 0x03, 0x00, 0x1f, 0x00, 0x00 }, // '1' C
  { 0x0e, 0x04, 0x04, 0x0e, 0x00, 0x1f, 0x00, 0x00 }, // '2' I
  { 0x0c, 0x12, 0x12, 0x12, 0x02, 0x12, 0x08, 0x07 }, // '3' N
  { 0x1e, 0x10, 0x10, 0x1e, 0x10, 0x1e, 0x00, 0x1f }, // '4' E
  { 0x0e, 0x11, 0x11, 0x11, 0x15, 0x0e, 0x04, 0x1f }, // '5' Q
  { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1e }, // '6' +  (underbar)
  //
  { 0x11, 0x19, 0x15, 0x13, 0x11, 0x00, 0x00, 0x00 }, // 'n'   Four CCs used in NZ4logo (see above)
  { 0x00, 0x00, 0x00, 0x11, 0x19, 0x15, 0x13, 0x11 }, // 'N'
  { 0x1f, 0x02, 0x04, 0x08, 0x1f, 0x00, 0x00, 0x00 }, // 'z'
  { 0x00, 0x00, 0x00, 0x1f, 0x02, 0x04, 0x08, 0x1f }  // 'Z'
};


// @@@@@@@@@@ T - TILING FONT @@@@@@@@@@
#ifdef CPU_MEGA
  const 
#endif
byte tilingfont[][8]  { // "ABCDEFGHIJKLMNOPQRSTUVWXuvwx"
  { 0x0f, 0x07, 0x03, 0x08, 0x03, 0x07, 0x0c, 0x1d }, // 'A'   Geometric tiling pattern (4 CCs)  *****
  { 0x1e, 0x1c, 0x18, 0x02, 0x18, 0x1c, 0x06, 0x17 }, // 'B'               AB
  { 0x1d, 0x0c, 0x07, 0x03, 0x08, 0x03, 0x07, 0x0f }, // 'C'               CD
  { 0x17, 0x06, 0x1c, 0x18, 0x02, 0x18, 0x1c, 0x1e }, // 'D'
//
  { 0x0c, 0x07, 0x03, 0x00, 0x03, 0x07, 0x0c, 0x1c }, // 'E'   Geometric tiling pattern (4 CCs) ****
  { 0x06, 0x1c, 0x18, 0x00, 0x18, 0x1c, 0x06, 0x07 }, // 'F'               EF
  { 0x1c, 0x0c, 0x07, 0x03, 0x00, 0x03, 0x07, 0x0c }, // 'G'               GH
  { 0x07, 0x06, 0x1c, 0x18, 0x00, 0x18, 0x1c, 0x06 }, // 'H'
//
  { 0x1e, 0x1c, 0x10, 0x00, 0x00, 0x01, 0x07, 0x0e }, // 'I'   Geometric tiling pattern (4 CCs) ****
  { 0x0f, 0x07, 0x01, 0x00, 0x00, 0x10, 0x1c, 0x0e }, // 'J'               IJ
  { 0x0e, 0x07, 0x01, 0x00, 0x00, 0x10, 0x1c, 0x1e }, // 'K'               KL
  { 0x0e, 0x1c, 0x10, 0x00, 0x00, 0x01, 0x07, 0x0f }, // 'L'
//
  { 0x07, 0x03, 0x01, 0x00, 0x03, 0x07, 0x0c, 0x1c }, // 'M'   Geometric tiling pattern (4 CCs) ***
  { 0x1c, 0x18, 0x10, 0x00, 0x18, 0x1c, 0x06, 0x07 }, // 'N'               MN
  { 0x1c, 0x0c, 0x07, 0x03, 0x00, 0x01, 0x03, 0x07 }, // 'O'               OP
  { 0x07, 0x06, 0x1c, 0x18, 0x00, 0x10, 0x18, 0x1c }, // 'P'
//
  { 0x0f, 0x07, 0x01, 0x00, 0x00, 0x01, 0x07, 0x0f }, // 'Q'   Geometric tiling pattern (4 CCs) ***
  { 0x1e, 0x1c, 0x10, 0x00, 0x00, 0x10, 0x1c, 0x1e }, // 'R'               QR
  { 0x0f, 0x07, 0x01, 0x00, 0x00, 0x01, 0x07, 0x0f }, // 'S'               ST
  { 0x1e, 0x1c, 0x10, 0x00, 0x00, 0x10, 0x1c, 0x1e }, // 'T'
//
  { 0x0f, 0x07, 0x11, 0x1c, 0x1c, 0x11, 0x07, 0x0e }, // 'U'   Geometric tiling pattern (4 CCs) **
  { 0x1e, 0x1c, 0x11, 0x07, 0x07, 0x11, 0x1c, 0x0e }, // 'V'               UV
  { 0x0e, 0x07, 0x11, 0x1c, 0x1c, 0x11, 0x07, 0x0f }, // 'W'               WX
  { 0x0e, 0x1c, 0x11, 0x07, 0x07, 0x11, 0x1c, 0x1e }, // 'X'
//
  { 0x02, 0x0e, 0x08, 0x18, 0x03, 0x02, 0x0e, 0x08 }, // 'u'   Geometric tiling pattern (4 CCs) **
  { 0x08, 0x0e, 0x02, 0x03, 0x18, 0x08, 0x0e, 0x02 }, // 'v'               ab
  { 0x08, 0x0e, 0x02, 0x03, 0x18, 0x08, 0x0e, 0x02 }, // 'w'               cd
  { 0x02, 0x0e, 0x08, 0x18, 0x03, 0x02, 0x0e, 0x08 }, // 'x'
};


// @@@@@@@@@@ O,I,P,E,s,U INVADER FONTS @@@@@@@@@@
// O - Outvader (Invader legs out) 
#ifdef CPU_MEGA
  const 
#endif
byte outvaderfont[][8]  { // "abcde"
  { 0x0e, 0x15, 0x0e, 0x11, 0x00, 0x00, 0x00, 0x00 }, // 'a'  /oo\ row 0
  { 0x00, 0x0e, 0x15, 0x0e, 0x11, 0x00, 0x00, 0x00 }, // 'b'  /oo\ row 1
  { 0x00, 0x00, 0x0e, 0x15, 0x0e, 0x11, 0x00, 0x00 }, // 'c'  /oo\ row 2
  { 0x00, 0x00, 0x00, 0x0e, 0x15, 0x0e, 0x11, 0x00 }, // 'd'  /oo\ row 3
  { 0x00, 0x00, 0x00, 0x00, 0x0e, 0x15, 0x0e, 0x11 }  // 'e'  /oo\ row 4
};

// I - Invader  (Invader legs in)
#ifdef CPU_MEGA
  const 
#endif
byte invaderfont[][8]  { // "abcde"
  { 0x0e, 0x15, 0x0e, 0x0a, 0x00, 0x00, 0x00, 0x00 }, // 'a'  \oo/ row 0
  { 0x00, 0x0e, 0x15, 0x0e, 0x0a, 0x00, 0x00, 0x00 }, // 'b'  \oo/ row 1
  { 0x00, 0x00, 0x0e, 0x15, 0x0e, 0x0a, 0x00, 0x00 }, // 'c'  \oo/ row 2
  { 0x00, 0x00, 0x00, 0x0e, 0x15, 0x0e, 0x0a, 0x00 }, // 'd'  \oo/ row 3
  { 0x00, 0x00, 0x00, 0x00, 0x0e, 0x15, 0x0e, 0x0a }  // 'e'  \oo/ row 4
};

// P - Laser
#ifdef CPU_MEGA
  const 
#endif
byte laserfont[][8]  { // "12345_"
  { 0x00, 0x00, 0x00, 0x00, 0x04, 0x0e, 0x1f, 0x1f }, // '1'  frame 0
  { 0x00, 0x00, 0x04, 0x04, 0x04, 0x0e, 0x1f, 0x1f }, // '2'  frame 1
  { 0x04, 0x04, 0x04, 0x00, 0x04, 0x0e, 0x1f, 0x1f }, // '3'  frame 2
  { 0x04, 0x04, 0x00, 0x00, 0x04, 0x0e, 0x1f, 0x1f }, // '4'  frame 3
  { 0x04, 0x00, 0x00, 0x00, 0x04, 0x0e, 0x1f, 0x1f }, // '5'  frame 4
  { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f }  // '_'  Empty laser storage
};

// E - Explosion
#ifdef CPU_MEGA
  const 
#endif
byte kapowfont[][8]  { // "12345"
  { 0x00, 0x00, 0x00, 0x00, 0x00, 0x0e, 0x0e, 0x00 }, // '1'  frame 0
  { 0x00, 0x00, 0x00, 0x00, 0x15, 0x0e, 0x0e, 0x15 }, // '2'  frame 1
  { 0x00, 0x00, 0x00, 0x00, 0x11, 0x04, 0x04, 0x11 }, // '3'  frame 2
  { 0x00, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x11 }, // '4'  frame 3
  { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }  // '5'  frame 4
};

// s - Shield
#ifdef CPU_MEGA
  const 
#endif
byte shieldfont[][8]  { // "LRlr"
  { 0x0f, 0x1f, 0x1c, 0x00, 0x00, 0x00, 0x00, 0x00 }, // 'L'  LH half
  { 0x1e, 0x1f, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00 }, // 'R'  RH half
  { 0x00, 0x00, 0x0f, 0x1f, 0x1c, 0x18, 0x00, 0x00 }, // 'l'  LH half (lower shield for 20x4 LCD)
  { 0x00, 0x00, 0x1e, 0x1f, 0x07, 0x03, 0x00, 0x00 }  // 'r'  RH half (lower shield for 20x4 LCD)
};

// U - Mothership/UFO
// Six frames of 4-char animation. Gameplay stops and
// the mothership flies across the LCD screen.
#ifdef CPU_MEGA
  const 
#endif
byte UFOfont[][8]  { // "ABCDIJKLQRSTabcdijklqrst" 
  { 0x00, 0x03, 0x07, 0x0e, 0x1f, 0x07, 0x02, 0x00 }, // 'A'
  { 0x1e, 0x1f, 0x1f, 0x16, 0x1f, 0x0c, 0x00, 0x00 }, // 'B'
  { 0x00, 0x10, 0x18, 0x14, 0x1e, 0x18, 0x10, 0x00 }, // 'C'
  { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // 'D'
//  
  { 0x00, 0x01, 0x03, 0x06, 0x0f, 0x03, 0x01, 0x00 }, // 'I' 
  { 0x0f, 0x1f, 0x1f, 0x16, 0x1f, 0x06, 0x00, 0x00 }, // 'J'
  { 0x00, 0x18, 0x1c, 0x16, 0x1f, 0x1c, 0x08, 0x00 }, // 'K' 
  { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // 'L' 
//                                                                                                                                                                                        
  { 0x00, 0x00, 0x01, 0x03, 0x07, 0x01, 0x00, 0x00 }, // 'Q' 
  { 0x07, 0x1f, 0x1f, 0x16, 0x1f, 0x13, 0x00, 0x00 }, // 'R'
  { 0x00, 0x1c, 0x1e, 0x17, 0x1f, 0x0e, 0x04, 0x00 }, // 'S' 
  { 0x00, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00 }, // 'T'
//
  { 0x00, 0x00, 0x00, 0x01, 0x03, 0x00, 0x00, 0x00 }, // 'a'
  { 0x03, 0x0f, 0x1f, 0x16, 0x1f, 0x19, 0x10, 0x00 }, // 'b'                            
  { 0x10, 0x1e, 0x1f, 0x16, 0x1f, 0x07, 0x02, 0x00 }, // 'c'
  { 0x00, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00 }, // 'd'
//
  { 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00 }, // 'i'
  { 0x01, 0x0f, 0x1f, 0x16, 0x1f, 0x1c, 0x08, 0x00 }, // 'j'
  { 0x18, 0x1f, 0x1f, 0x16, 0x1f, 0x13, 0x01, 0x00 }, // 'k'
  { 0x00, 0x00, 0x00, 0x10, 0x18, 0x00, 0x00, 0x00 }, // 'l'
//
  { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // 'q'
  { 0x00, 0x07, 0x0f, 0x16, 0x1f, 0x0e, 0x04, 0x00 }, // 'r'
  { 0x1c, 0x1f, 0x1f, 0x16, 0x1f, 0x19, 0x00, 0x00 }, // 's' 
  { 0x00, 0x00, 0x10, 0x18, 0x1c, 0x10, 0x00, 0x00 }  // 't' 
};

/*----------------------------------------------*/
/*  Define the CustomFont struct using typedef  */
/*----------------------------------------------*/
typedef struct {
  char fontFlag;
#ifdef CPU_MEGA
  const 
#endif
  byte (*fontBits)[8];  // Pointer to the CC bitmap arrays.
  String fontChars;
} CustomFont;

/*----------------------------------------------*/
/* Create instances of the CustomFont struct,   */
/*  and assemble into a CustomFont array of     */
/*        struct, one array per font            */
/*----------------------------------------------*/
// Order of fields: fontFlag, fontBits,  fontChars
CustomFont font0  = { 'G', bargraphfont, "abcLR!876543210" }; // 15 (order corrected!) Previously was wrong: "0abcLR!87654321" 
CustomFont font1  = { '0', big0font, "ABCD" }; // 4      Location of the parts forming two bignums on-screen: 
CustomFont font2  = { '1', big1font, "ABCD" }; // 4                AB  A'B'
CustomFont font3  = { '2', big2font, "ABCD" }; // 4                CD  C'D'
CustomFont font4  = { '3', big3font, "ABCD" }; // 4       A maximum of two bignums digits!
CustomFont font5  = { '4', big4font, "ABCD" }; // 4
CustomFont font6  = { '5', big5font, "ABCD" }; // 4
CustomFont font7  = { '6', big6font, "ABCD" }; // 4
CustomFont font8  = { '7', big7font, "ABCD" }; // 4
CustomFont font9  = { '8', big8font, "ABCD" }; // 4
CustomFont font10 = { '9', big9font, "ABCD" }; // 4
CustomFont font11 = { 'S', symbolfont, "DSTMH><^vuds_1234KkLQnNbCFefghijc" }; // 33
CustomFont font12 = { 'B', Boldfont, "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" }; // 36
CustomFont font13 = { 'b', boldlcfont, "abcdefghijklmnopqrstuvwxyz" }; // 26
CustomFont font14 = { 'l', lowercasefont, "gjpqym" }; // 6
CustomFont font15 = { 'c', smallcapsfont, "ABDEFGHIJKLMNPQRTUY" }; // 19
CustomFont font16 = { 'f', smlfrequfont, "kHz" }; // 3
CustomFont font17 = { 'v', smlrevcapsfont, "BCFLSTR" }; // 7  
CustomFont font18 = { 'V', revcapsfont, "ABCDEFGHIKLOPRSTUVXYZ0123456789=:" }; // 33
CustomFont font19 = { 'C', channelfont, "241dca5b3ef6xyzuvwjkl" }; // 21
CustomFont font20 = { 'L', logofont, "LRdtsHDC0123456nNzZ" }; // 19
CustomFont font21 = { 'T', tilingfont, "ABCDEFGHIJKLMNOPQRSTUVWXuvwx" }; // 28
CustomFont font22 = { 'O', outvaderfont, "abcde" }; // 5
CustomFont font23 = { 'I', invaderfont, "abcde" }; // 5
CustomFont font24 = { 'P', laserfont, "12345_" }; // 6
CustomFont font25 = { 'E', kapowfont, "12345" }; // 5
CustomFont font26 = { 's', shieldfont, "LRlr" }; // 4
CustomFont font27 = { 'U', UFOfont, "ABCDIJKLQRSTabcdijklqrst" }; // 24

CustomFont fonts[] = { font0,  font1,  font2,  font3,  font4,  font5,  font6,
                       font7,  font8,  font9,  font10, font11, font12, font13,
                       font14, font15, font16, font17, font18, font19, font20,
                       font21, font22, font23, font24, font25, font26, font27 };


/*----------------------------------------------*/
/* getBitmap() - FETCH CUSTOM CHARACTER BITMAPS */
/*----------------------------------------------*/
// This function returns the bitmap for a fontFlag, fontChar pair.
// NOTES: The foreach loop (a.k.a "range-based for loop"), introduced with C++11,
// simplifies traversal over an iterable data set. It does this by eliminating the
// initialization process and traversing over each and every element rather than an iterator.
#ifdef CPU_MEGA
  //Fonts in flash (ATmega 2560 only. Requires other changes to bitmap declarations and struct):
  uint8_t* getBitmap(char myfontChar, char myfontFlag) {
  for (const CustomFont& font : fonts) {
    if (font.fontFlag == myfontFlag) {
      int charIndex = font.fontChars.indexOf(myfontChar);
      if (charIndex != -1) {
        static uint8_t bitmap[8];
        for (int i = 0; i < 8; i++) {
          bitmap[i] = pgm_read_byte_near(font.fontBits[charIndex] + i);
        }
        return bitmap;
      }
    }
  }
  return nullptr; // Font or Char not found
}
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#elif defined(CPU_UNO_R4)
  uint8_t* getBitmap(char myfontChar, char myfontFlag) {
  for (const CustomFont& font : fonts) {
    if (font.fontFlag == myfontFlag) {
      int charIndex = font.fontChars.indexOf(myfontChar);
      if (charIndex != -1) return font.fontBits[charIndex];
    } 
  }
  return nullptr; //  Font or Char not found
}
#endif


/*****************************************************************/
/*  replaceEvenCCids() - Replace CC_ids on Even Byte Boundaries  */
/*                                                               */
/*  (This custom function is a rewrite of the built-in String    */
/*  replace function to operate on even byte boundaries only)    */
/*****************************************************************/
String  replaceMatchingEvenCCids(String input, String current_CC_id, String replacement) { 
  String result = "";
  int length = input.length();
  for (int i = 0; i < length - 1; i += 2) {
    if ((input.charAt(i) == current_CC_id[0]) && (input.charAt(i + 1) == current_CC_id[1])) result += replacement;
    else {
    result += input.charAt(i);
    result += input.charAt(i + 1);
    }
  }
  return result;
}


/*******************************************************************************/
/* setupRow123() - Set up the next line for 2- 3- or 4-row CC graphics         */
/*                                                                             */
/* Usage Examples:                                                             */
/*                                                                             */
/*     // Display a 3x2 surround sound channel 'daisy'                         */   
/*     clearTheStage();                                                        */
/*     startPos = 0; // A number between 0 and 39 (20x2 LCD) or 79 (20x4 LCD)  */
/*     lcdString = daisy[5];                                                   */
/*     LCDfontManager();                                                       */
/*     setupRow123();                                                          */
/*     LCDfontManager();                                                       */
/*                                                                             */
/*     // Display a 3x2 surround sound channel 'daisy'                         */   
/*     clearTheStage();                                                        */
/*     startPos = 1; // A number between 0 and 39 (20x2 LCD) or 79 (20x4 LCD)  */
/*     lcdString = "2f2|CCC" "1e1|CCC";                                        */
/*     LCDfontManager();                                                       */
/*     setupRow123();                                                          */
/*     LCDfontManager();                                                       */
/*                                                                             */
/*     // Display the NZ4logo centered on a 20x4 LCD:                          */
/*     clearTheStage();                                                        */
/*     startPos = 29; // (use 9 for a 20x2 LCD)                                */
/*     lcdString = "NZ|LL" "zn|LL";                                            */
/*     LCDfontManager(); // Row 0                                              */
/*     setupRow123();                                                          */
/*     LCDfontManager(); // Row 1                                              */
/*                                                                             */ 
/*******************************************************************************/
void setupRow123() {
  startPos = startPos + 20; // Update startPos for next line in multi-line CCs.
  lcdString = lcdString.substring((lcdString.indexOf('|') << 1) + 1);
  return;
}

/*************************************************************/
/*         TileIt() - Fill LCD with custom 2x2 tiles         */
/*                                                           */ 
/*  LH margin is set by startPos (0-18).                     */
/*  Odd StartPos does not plot a half-pattern in column 19   */ 
/*************************************************************/
void TileIt() {
uint8_t len = lcdString.length()/2;
String evenRow = "";
String oddRow = "";
String fontFlags = "";
for (uint8_t m = startPos; m < (20/len + startPos/2); m++) {
  evenRow += lcdString.substring(0,len);
  oddRow += lcdString.substring(len);
  fontFlags += "TT";
  }
evenRow += ('|' + fontFlags);
oddRow += ('|' + fontFlags);
lcdString = evenRow;
LCDfontManager();
startPos += 20;
lcdString = oddRow;
LCDfontManager(); 
startPos += 20;
lcdString = evenRow;
LCDfontManager();
startPos += 20;
lcdString = oddRow;
LCDfontManager();
return;
}


/*----------------------------------------------------*/
/* clearTheStage() - Clears the LCD 'stage', making   */
/* it ready for a new LCD 'scene' composed of one or  */
/* several lcdStrings.                                */
/*                                                    */
/*         Clears the LCD, the CC_id_table[],         */  
/*          the LCD CGRAM, and screenImage.           */
/*           (0.11 seconds for a 20x4 LCD)            */
/*----------------------------------------------------*/
void clearTheStage() {
  for (CGRAM_ptr = 0; CGRAM_ptr < 8; CGRAM_ptr++) {
    CC_id_table[CGRAM_ptr] = "";  // Clears out CC_id_table [0 to 7].
    lcd.createChar(CGRAM_ptr, blankBitmap); delay(1); // Blank out all 8 CGRAM locations.
  }
  screenImage = ""; 
  for (int i = 0; i < screenLength; i++) screenImage += " "; // Fill the screen buffer with spaces
  lcd.clear(); // Clear LCD and place cursor at top left (0,0).
  return;
}


/*-----------------------------------------------------*/
/* CC_clear - Clear custom characters from the         */
/*            HD44780 CGRAM and the CC-id_table.       */
/*                                                     */
/* Clears the CC_id_table[] and the LCD CGRAM.         */
/* Occasionally useful when doing animation frames,    */
/* but only if there are no other CCs on-screen!       */
/*                                                     */
/* This function may solve a transient display problem */
/* that is sometimes incurred during fast animation    */
/* frames, which sometimes shows as a brief 'ghosting' */
/* of old CCs, before they are cleared from the LCD.   */
/* It is caused by the 50 ms (estimated) time delay    */
/* between creating a CC in CGRAM and displaying it on */
/* the LCD.                                            */
/*-----------------------------------------------------*/
void CC_clear() {
  for (CGRAM_ptr = 0; CGRAM_ptr < 8; CGRAM_ptr++) {
    CC_id_table[CGRAM_ptr] = "";  // Clears out CC_id_table [0 to 7].
    lcd.createChar(CGRAM_ptr + 8, blankBitmap); delay(1); // Blank out all 8 CGRAM locations.
  }
}  


/*---------------------------------*/
/*    LCDsplash() - LCD SIGN-ON    */
/* (Does not use the font manager) */
/*---------------------------------*/
// Uses CGRAM locations 8,9,10,11,12.
void LCDsplash() {
byte my_F[8]    = { 0x1f, 0x18, 0x18, 0x1e, 0x18, 0x18, 0x18, 0x00 }; // Bold F
byte my_P[8]    = { 0x1e, 0x19, 0x19, 0x19, 0x1e, 0x18, 0x18, 0x00 }; // Bold P
byte myBar8[8]  = { 0x1b, 0x1b, 0x1b, 0x1b, 0x1b, 0x1b, 0x1b, 0x1b }; // Bar graph = 8
byte myBar6[8]  = { 0x00, 0x00, 0x1b, 0x1b, 0x1b, 0x1b, 0x1b, 0x1b }; // Bar graph = 6
byte myBar4[8]  = { 0x00, 0x00, 0x00, 0x00, 0x1b, 0x1b, 0x1b, 0x1b }; // Bar graph = 4
byte my_star[8] = { 0x04, 0x15, 0x0e, 0x1f, 0x0e, 0x15, 0x04, 0x00 }; // custom '*' char 1 
lcd.createChar(8,my_F);
lcd.createChar(9,my_P);
lcd.createChar(10,myBar4);
lcd.createChar(11,myBar6);
lcd.createChar(12,myBar8);
lcd.createChar(13,my_star);
lcd.setCursor(0,0);
// Very important: DO NOT embed byte(0) in Strings, and don't try to print it to the LCD!!! (it's equivalent to \0, the
// end-of-c-string null character). The issue arises because Hitachi HD44870 LCD controllers use byte(0) as a CGRAM address.
// Fortunately, the CGRAM 0x00-0x07 addresses are mirrored from 0x08-0x0f. Those embed in Strings without problems!
lcd.write(byte(13));lcd.print("-----");
lcd.write(byte(8));lcd.print("ont ");
lcd.write(byte(9));lcd.print("al------"); 
lcd.setCursor(0,1);
for(uint8_t i = 0; i < 3; i++) lcd.write(byte(10)); //4
lcd.print("3");
for(uint8_t i = 0; i < 3; i++) lcd.write(byte(11)); //6
lcd.print(".");
for(uint8_t i = 0; i < 4; i++) lcd.write(byte(12)); //8
lcd.print("0");
for(uint8_t i = 0; i < 3; i++) lcd.write(byte(11)); //6
lcd.print("2");
for(uint8_t i = 0; i < 3; i++) lcd.write(byte(10)); //4
delay(1000);
} 


/*---------------------------------*/
/*         printStringHex()        */
/*---------------------------------*/
void printStringHex(const String& myString) {
  String Interp = ""; 
  Serial.print(" ");
  for (size_t i = 0; i < myString.length(); ++i) 
  {
    char c = myString.charAt(i);
    Interp = Interp + String(c); // + "   ";
    if (c > 15) Serial.print("0x"); 
    else Serial.print("0x0");
    Serial.print(c, HEX); // Print the character as a hexadecimal value
    Serial.print(" ");    // Add inter-character space
  }
  Serial.print(Interp);
  //Serial.println(); // Print a newline at the end
}

/*---------------------------------------------*/
/* ++++++++++++++++ S E T U P ++++++++++++++++ */
/* ++++++++++++++++ S E T U P ++++++++++++++++ */
/* ++++++++++++++++ S E T U P ++++++++++++++++ */
/*---------------------------------------------*/
void setup() {
  #ifdef LCD_INTERFACE_4BIT
    #ifdef LCD_SIZE_16x2
      lcd.initbegin(16, 2); // cols, rows
    #elif defined(LCD_SIZE_20x2)
      lcd.begin(20, 2);
    #elif defined(LCD_SIZE_20x4)
      lcd.begin(20, 4);
    #endif
  #endif

  #ifdef LCD_INTERFACE_I2C
    lcd.init();
    lcd.backlight(); // Turn on LCD backlight
  #endif
  lcd.clear(); 
  Serial.begin(9600);
  //myFontsPrinter(); // FOR DEBUG & MAINTENANCE ONLY
  LCDsplash();delay(3000); // Uncomment this line to perform a basic LCD test.
  clearTheStage(); // Initialize the font manager. Use prior to building an 'LCD Scene'.
  //
  // Suggestion: Edit the following six or seven lines to create an alternative to 
  // Font Pal's built-in LCDsplash() screen:
  //   startPos = 0;
  //   lcdString = "   TheaterMaster         SIGNATURE      |"
  //               "   BbbbbbbBbbbbb                        ";
  //   LCDfontManager();
  //   delay(3000);
}


/*---------------------------------------------*/
/* ++++++++++++++++  L O O P  ++++++++++++++++ */
/* ++++++++++++++++  L O O P  ++++++++++++++++ */
/* ++++++++++++++++  L O O P  ++++++++++++++++ */
/*---------------------------------------------*/
void loop() {

//*
//------------------------------------------------------------------------------
// TILING TEST 1
// File a 20x4 LCD with a 2x2 tiling pattern
clearTheStage(); 
startPos = 0;
lcdString = "ABABABABABABABABABAB|TTTTTTTTTTTTTTTTTTTT"  // 4 unique CCs
            "CDCDCDCDCDCDCDCDCDCD|TTTTTTTTTTTTTTTTTTTT"
            "ABABABABABABABABABAB|TTTTTTTTTTTTTTTTTTTT"
            "CDCDCDCDCDCDCDCDCDCD|TTTTTTTTTTTTTTTTTTTT";
LCDfontManager(); 
setupRow123(); 
LCDfontManager(); 
setupRow123(); 
LCDfontManager(); 
setupRow123(); 
LCDfontManager(); 
delay(2000);
//while(true){} 
//*/

//*
//------------------------------------------------------------------------------
// TILING TEST 2
// File a 20x4 LCD with a 2x2 tiling pattern, LH margin is StartPos.
//clearTheStage(); 
//startPos = 0;
//lcdString = myTile[0]; // Values 0-6 are defined above.
//TileIt();
//delay(3000);
//while(true){}

startPos = 10; // Fill RH half of screen with a different tile pattern (Note: Each pattern uses 4 CCs for a total od 8).
lcdString = myTile[4];
TileIt();
delay(3000);
//------------------------------------------------------------------------------
//*/

//*
// Display the NZ4logo on a 20x4
// New Zealand logo inspired by Louise Kellerman's logo for the 10th Commonwealth Games, Chchristchurch, 1974).

clearTheStage(); 
for (uint8_t i = 0; i <= 40; i += 40) {
  startPos = i;
  lcdString = "NZ NZ NZ NZ NZ NZ NZ|LL LL LL LL LL LL LL"
              "zn zn zn zn zn zn zn|LL LL LL LL LL LL LL";
  LCDfontManager(); 
  setupRow123(); 
  LCDfontManager(); 
}
delay(3000);
//while(true){} 
//*/

//*
// Display the NZ4logo centered on a 20x4
clearTheStage(); 
startPos = 29; // (Note: Change 29 to 9 for a 20x2 LCD)
lcdString = NZ4logo;
LCDfontManager(); 
setupRow123(); 
LCDfontManager();
delay(3000); 
//while(true){} 
//*/

/*
// WRITE 80 CHARACTERS OF PLAIN TEXT TO A 20x4 LCD
// This takes 0.14 seconds (0.25 with clearTheStage), a speed
// that cannot be matched by Font-Pal's font-formatted writes.
  //clearTheStage(); // Not needed because we're not writing CCs
  startPos = 0;
  lcdString = "Scientific consensusis an oxymoron; science values evidence,not majority opinion";   // 80 characters of plain text
  LCDfontManager();
  delay(3000);
//while(true) {};
*/

/*
// Test 4-line LCD:
  clearTheStage();
  startPos = 0;
  lcdString = "AFAFAFAFAFAFAFAFAFAF|"
              "BBBBBBBBBBBBBBBBBBBB"
              "BFBFBFBFBFBFBFBFBFBF|"
              "BBBBBBBBBBBBBBBBBBBB"
              "CFCFCFCFCFCFCFCFCFCF|"
              "BBBBBBBBBBBBBBBBBBBB"
              "DFDFDFDFDFDFDFDFDFDF|"
              "BBBBBBBBBBBBBBBBBBBB"
              "EFEFEFEFEFEFEFEFEFEF|"
              "BBBBBBBBBBBBBBBBBBBB";
  LCDfontManager(); // Row 0
  setupRow123();
  LCDfontManager(); // Row 1
  setupRow123();
  LCDfontManager(); // Row 2
  setupRow123();
  LCDfontManager(); // Row 3
  delay(3000);
//while(true) {};

// Test startPos with 4-row formatted String on a 4-line LCD:
  clearTheStage();
  startPos = 5;
  lcdString = "FAFAFAFAFAFAFAF|"
              "BBBBBBBBBBBBBBB"
              "FBFBFBFBFBFBFBF|"
              "BBBBBBBBBBBBBBB"
              "FCFCFCFCFCFCFCF|"
              "BBBBBBBBBBBBBBB"
              "FDFDFDFDFDFDFDF|"
              "BBBBBBBBBBBBBBB"
              "FEFEFEFEFEFEFEF|"
              "BBBBBBBBBBBBBBB";
  LCDfontManager(); // Row 0
  setupRow123();
  LCDfontManager(); // Row 1
  setupRow123();
  LCDfontManager(); // Row 2
  setupRow123();
  LCDfontManager(); // Row 3
  delay(3000);
//while(true) {};
// ===================END OF 20x4 TESTS
*/


// - - - - - - - - - - - S P E C I A L  T E S T - - - - - - - - - - - - - - - - - 
// A test related to David_2018's patch:
  clearTheStage(); // Prepare the font manager for a new 'LCD scene'.
  startPos = 0;
  lcdString = "   TheaterMaster         SIGNATURE      |"
              "   BbbbbbbBbbbbb                        ";
  LCDfontManager();
  delay(3000);
  
  startPos = 10;
  lcdString = "Master OK|"    // The 'OK' is to let you know that something happened.
              "Bbbbbb   ";
  LCDfontManager();
  delay(1000);
//while(true){}; 

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Another test related to David 2018's patch.
// The following test constructs an LCD scene from several parts to verify that font-formatted text
// written into a second field that partially overlaps a previously written font-formatted field will
// not affect those font-formated characters that remain not overwritten.
// In both test cases (which differ in the way the fields overlap) the result of writing ten bold "I"
// characters is "ABCDEFGIIIIIII Text!", and "My IIIIIIIIIIBCDEFGH", respectively.
//-----SCENE 1:
clearTheStage();
startPos = 0;
lcdString = "ABCDEFGH Plain Text!|"
            "BBBBBBBB            ";
LCDfontManager();
delay(2000);

startPos = 7;
lcdString = "IIIIIII|"  
            "BBBBBBB"; 
LCDfontManager();
delay(2000);

//-----SCENE 2:
clearTheStage();
startPos = 0;
lcdString = "Plain Text! ABCDEFGH|"
            "            BBBBBBBB";
LCDfontManager();
delay(2000);

startPos = 3;
lcdString = "IIIIIIIIII|" 
            "BBBBBBBBBB"; 
LCDfontManager();
delay(2000);
// - - - - - - - - - - E N D  O F  S P E C I A L  T E S T - - - - - - - - - - - - 


/*
clearTheStage();
startPos = 0;
lcdString = "B AB BAB Plain Text!|" // Row 0 should be: [B AB BAB Plain Text!] OK
            "B B  BBB            "  // 
            "B AA BAA BAEbHIJKXYZ|" // Row 1 should be: [B AA BAA BAE@HIJKX##] OK 
            "B BB BBB BBBBBBBBBBB"; 
LCDfontManager();
setupRow123();
LCDfontManager();
delay(3000);
//while(true){}

 clearTheStage();
 startPos = 0;
 lcdString = "B A BBBBBAADEFGHIJKZ|" // Row 0 should be: [B A BBBBBAADEFGHI###] OK
             "B B BBBBBBBBBBBBBBBB"  
             "B AB B sB BAB AAAZ s|" // Row 1 should be: [B AB B #B BAB AAA# @] OK
             "B BB B bB BBB BBBB q"; 
 LCDfontManager();
 setupRow123();
 LCDfontManager();
 delay(3000);
//while(true){}
*/


// ============================================================================
// EXAMPLES OF LCD 'SCENE CONSTRUCTION' and COMPOSITE CC CREATION FOR 20x4 LCDs:
// ============================================================================
//
// (i) clearTheStage() is generally used once only, before any LCD looping. An
// exception to this would be if we jump out of that loop to display a bignums
// volume up/dpwm adjustment screen (which also uses all 8 CCs). After that, and
// before restarting the readout loop shown in this example, clearTheStage() would
// once again be called. This test example loops through various status readouts,
// in sequence, emulating a user changing the input source signal. A good place
// for the initial clearTheStage() might be at the end of void Setup(). 
//
// (ii) Perhaps not obvious, is that the source channel readout custom characters
// (the 'daisy[n] CC strings') have two rows, and therefore require a call to the
// setupRow123() function and a second call to LCDfontManager(). As suggested by
// the name setup123(), this function can be used to construct composite CCs having
// one, two, three, or four rows, keeping in mind that there are only eight CCs.
// Plain text can be inserted at no CC cost (as shown) as long as the "|" marker
// structure is maintained. As is usual in Font-Pal, CC can be repeated at no cost.
// An advantage of using setupRow123 is that all rows of the composite CC start at
// the same place on each row. The following editor format (shown for a 20x4 LCD)
// can simplify the design process. Of course, the strings can be assembled in
// Strings or String arrays, as constants or on-the-fly as String variables.
//
// (iii) Perhaps less obvious is that lcdStrings written to the LCD must often be
// padded with spaces, not only to prevent fragments of prior lcdStrings from being
// visible, but also because this is how Font Pal purges any CCs referenced by the
// overwritten String from the CC_id_table, thereby freeing up those table locations
// for new lcdStrings and their CC references. This is why, generally, we don't need
// to have a line of code like the following to free up CC_id_table locations:
//      startPos = 4; lcdString = "                "; LCDfontManager();
// The only case I can think of where this line might be needed is if a field is
// purposefully blanked. A non-font-formatted string of plain-text spaces is 
// sufficient for this purpose.
//
// Three examples of creating large composite CCs for a 20x4 LCD follow:

/*
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// EXAMPLE: CONSTRUCTING AND PLACING A FOUR-LINE COMPOSITE CC:
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// Note: The leading space erases the previous CC faster than clearTheStage(); can.
clearTheStage(); // Clear LCD image and CCs prior to 'building an LCD Scene'
for(int i = 3; i < 12; i++) {
  startPos = i;
  lcdString = " SDb|" // Total CCs = 13 , 8 unique. 
              " SSS"
              " u|"  // The font flags must be the same length as the char flags.
              " S"   // In this case they are both length 1.
              " dKkDSb|" // The font flags must be the same length as the char flags.   
              " SSSSSS"
              " A = uK|" // The font flags must be the same length as the char flags.
              " B   SS"; // In this case they both are length 6.
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  delay(1000); // Enough time to see the result
  }
//while(true){} 
*/   


 // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 // EXAMPLE: CONSTRUCTING A TEXT FRAME WITH CCs:
 // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 clearTheStage(); // Clear LCD image and CCs prior to 'building an LCD Scene'
 startPos = 0;
 lcdString = "effffffffffffffffffg|" // Total CCs = 44, 8 unique.
             "SSSSSSSSSSSSSSSSSSSS"
             "c   DON'T PANIC    h|"
             "S                  S"
             "c Mostly Harmless! h|"
             "S                  S"
             "j_____________hhgg_i|"    
             "SSSSSSSSSSSSSS    SS";
 LCDfontManager();
 setupRow123();
 LCDfontManager();
 setupRow123();
 LCDfontManager();
 setupRow123();
 LCDfontManager();
 delay(3000);
//while(true){}
     

//*
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// EXAMPLE: CONSTRUCTING A 20x4 SPLASH SCREEN FOR A FANTASY DIGITAL SURROUND SOUND SYSTEM:
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%$$$$$%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// Although the setupRow123() routine was originally intended to make multi-row CC objects
// (such as the example of channel daisies or some of the logos) not only easier to manage,
// but also easy to position anywhere on the LCD (all such rows automaticallyl offset their
// position from the one startPos), the mechanism can also be used to advantage in designing
// and managing the layout of entire screens. As the following example of a 20x4 splash
// screen shows, setupRow123() allows the app developer to map the IDE editor's text grid
// directly to the LCD screen layout, helping to simplify the screen design process and 
// msking lsyouts easier to verify.
// 
// That said, whenever we display text objects on the LCD that have no particular positional
// relationship row-to-row, writing a long String to the whole screen as a single String has
// a run-time speed advantage. Moreover, it will still sometimes be necessary to customize
// the method because plain-text lines lack a '|' font marker. Moreover, the straightforward
// approach using a single startPos and setupRow123() may not work if the LH edge of a multi-
// row CC does not line up. Fortunately there are various work-arounds for such cases. In the
// case of a CC which has a one-line plain text gap, that line can be combined with the next
// line, as follows (while saving time by eliminating one call to LCDfontManager):  
 clearTheStage(); 
 startPos = 0;
 lcdString = "23332 Fantasy 10.3  |" // Total CCs = 24, 8 unique.
             "CCCCC       l       "
             "16661 Surround Sound|"
             "CCCCC               "
             "  (5/5/.3 channels)   KKKK K NNN L LLLL |" // This line shows how we handle a plain-text line by
             "                      SSSS S SSS S SSSS "; // running it on to the next line within a composite CC.
 LCDfontManager(); // LCD line 1
 setupRow123();
 LCDfontManager(); // LCD line 2             
 setupRow123();
 LCDfontManager();  // LCD lines 3 and 4
 delay(6000);
//while(true){}


 
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// EXAMPLE: CONSTRUCTING AN APPLICATION 'SCENE' FROM SEVERAL SMALLER STRINGS AND CCs.
// (Emulating the front panel 20x2 LCD display of a home theater surround sound audio processor)
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 clearTheStage(); // Clear LCD image and CCs prior to 'building an LCD Scene'
 startPos = 0; 
 lcdString = "   TheaterMaster         SIGNATURE      |" 
             "   BbbbbbbBbbbbb                        ";
 LCDfontManager();
 delay(3000);

 // No signal on input D3 -----------------------------
 clearTheStage(); // Clear LCD image and CCs for an extended 'LCD Scene' 
 startPos = 32;
 lcdString = "-24.5 dB"; // 0 CCs 
 LCDfontManager();
 delay(100);

 startPos = 24;
 lcdString = "D3:DVD";  // 0 CCs   An example of a plain-text string. 
 LCDfontManager();
 delay(100);
  
 startPos = 4;
 lcdString = "No Signal       |"  // 1 CC. String is padded with spaces to the end of the field.
              "     l          ";
 LCDfontManager();
 delay(100);
  
 startPos = 0;
 lcdString = daisy[7]; // 0/0/0 channel configuration undefined (no signal) (4 CCs)
 LCDfontManager();
 setupRow123();
 LCDfontManager();
 delay(1000);

 // Dolby Digital 5.1 on input D1 -----------------------------
 //clearTheStage();
 startPos = 24;
 lcdString = "D1:Sat";  // 0 CCs   An example of a non font-encoded string.
 LCDfontManager();
 delay(100);

 startPos = 4; 
 lcdString = "LR Digital 5.1  |" // 3 CCs. String is padded with spaces to the end of the field.
             "LL   l          ";
 LCDfontManager();
 delay(100);

 startPos = 0;
 lcdString = daisy[8]; // 3/2/0.1 ('5.1') channel configuration (4 CCs)
 LCDfontManager();
 setupRow123();
 LCDfontManager();
 delay(1000);

 // DTS ES 6.1 on input D2 -----------------------------
 //clearTheStage();
 startPos = 24;
 lcdString = "D2:Blu";  // 0 CCs   An example of a non font-encoded string.
 LCDfontManager();
 delay(100);
  
 startPos = 4; 
 lcdString = "dts ES 6.1      |" // 4 CCs. Padded out with spaces to match the length of the field. 
             "LLL             ";
 LCDfontManager();
 delay(100);

 startPos = 0;
 lcdString = daisy[16];  // 3/3/0.1 ('6.1') channel configuration (4 CCs)
 LCDfontManager();
 setupRow123();
 LCDfontManager();
 delay(1000);
 //while(true){}


//*
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// EXAMPLE: CONSTRUCTING A BIG-NUMS READOUT ON A 20x2 LCD:
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%$$$$$%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  clearTheStage();
  startPos = 5;   
  lcdString = "ABABABAB   |88880000   "   // Double-row Strings must
              "CDCDCDCDPro|88880000   ";  // be of equal length! Correct: 8800Pro
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  delay(3000);
//*/

// =====================
// MISCELLANEOUS TESTS:
// =====================

/*
// Test of 20x2 LCD display wrap-around for font-formatted text.
  clearTheStage();
  startPos = 0; 
  lcdString = "All Bold A A A A A A A A A A A A A A A B|" 
              "    B    B B B B B B B B B B B B B B B B";
  LCDfontManager();
  delay(3000);
*/

/*
// Test of auto-replacement of CCs in a 20x4 LCD: 
  clearTheStage();
  startPos = 0;   
  lcdString = "All Bold AAAAAAAAAAA|" // Total CCs = 72, 2 unique 
              "    B    BBBBBBBBBBB"   
              "AAAAAAAAAAAAAAAAAAAA|"  
              "BBBBBBBBBBBBBBBBBBBB"
              "AAAAAAAAAAAAAAAAAAAA|"  
              "BBBBBBBBBBBBBBBBBBBB"
              "AAAAAAAAAAAAAAAAAAAB|"  
              "BBBBBBBBBBBBBBBBBBBB";
  LCDfontManager(); // 1st Row
  setupRow123();
  LCDfontManager(); // 2nd Row
  setupRow123();
  LCDfontManager(); // 3rd Row
  setupRow123();
  LCDfontManager(); // 4th Row
  delay(3000);
*/

/*
// Test if 20x4 LCD wrap-around and auto-replacement of CCs.
// NOTE: This form renders faster, but is more time-consuming to check against the screen layout.
//       (This test should produce output that is identical to that produced by the previous test)
  clearTheStage();
  startPos = 0;   
  lcdString = "All Bold AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB|" // Total CCs = 72, 2 unique 
              "    B    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB"; 
  LCDfontManager();
  delay(1000);
*/

/*
// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
// INVADER SPLASH SCREEN FOR 20x4 LCD (7 CCs, 7 unique)
// Note: Game construction is a little out of Font-Pal's league, therefore I've included
// the following purely as an example that may inspire others in their own Font-Pal pursuits.
// 
// This "game demo" if I can call it that is the Font-Pal version of a demo I wrote prior to
// the existence of Font-Pal. Many things worked OK when converted to Font-Pal scripts, but
// the mothership fly-by was not one of them. As the mothership proceeded L to R across the
// screen, every 5th animation frame would show as a brief ghost in the previous character
// position, before showing normally. This turned out to be caused by the time delay between 
// writing 4 new animation frame CCs to the CGRAM and writing those CCs onto the LCD one 
// character position to the right. Although there is no cure for this within Font-Pal, it
// does not affect normal use of CCs as part of font-formatted screen text. An it affects CC
// animation only when successive frame are displayed at different screen positions (as is
// the case in the mothership fly-by). The solution, at least for this part of Space Invaders
// is to bypass Font-Pal and write the animation frames directly to the LCD with essentially
// no delay. The ghosting is not the result of a Font-Pal bug, but rather is a feature of the
// HD44780: When we update a CGRAM location (of which there are only eight), this instantly
// affects all screen characters that are mapped to that CGRAM location. This should help
// explain some of the transient effects we observed on HD44780-equipped LCD panels. 
// This is why the Font-Pal Space Invaders test scripts remain inclomplete. 
//
clearTheStage();
delay(500);
startPos = 20;
lcdString = "   Space Invaders   |"
            "   Bl    B          "
            "   b-     ABC-      |"
            "   I      UUU       ";
LCDfontManager();
setupRow123();
LCDfontManager();
delay(800);
startPos = 45;
lcdString = "2";  // Add points.
LCDfontManager();
delay(200);
startPos = 46;
lcdString = "5";
LCDfontManager();
delay(400);
startPos = 54;
lcdString = "1";
LCDfontManager();
delay(200);
startPos = 55;
lcdString = "0";
LCDfontManager();
delay(200);
startPos = 56;
lcdString = "0";
LCDfontManager();
delay(1500); 

// INVADER GET READY! SCREEN FOR 20x4 LCD (3 CCs, 2 unique)
clearTheStage();
startPos = 0;
lcdString = "                 000"
            "       GET          "
            "      READY!        ";
LCDfontManager();
delay(1000);
startPos = 77;
lcdString = "111|PPP"; // Stock up on lasers.
LCDfontManager();
delay(1000);
startPos + 77;
lcdString = "_|P"; // Show one laser used/in use: '_'
LCDfontManager();
delay(500);

// INVADER GAME SCREEN FOR 20x4 LCD
clearTheStage();
startPos = 0;
lcdString = "                 000"
            "                    ";
LCDfontManager();

startPos = 40;
lcdString = "  lr lr   lr lr     |"
            "  ss ss   ss ss     "
            "        3         11|"
            "        P         PP";
LCDfontManager();
setupRow123();
LCDfontManager();
for (int8_t row = 0; row < 5; row++) {   // rows 0 to 4
  for (int8_t col = 0; col < 7; col++) { // cols 0 to 6
    if (col % 2) lcdString = invArray[row][0]; else lcdString = invArray[row][1]; 
    if (row % 2) startPos = 6 - col; else startPos = col; 
    LCDfontManager();
    startPos = startPos + 20;
    LCDfontManager();
    delay(300);
  }
}
delay(1000);

// Mothership fly-by omitted.

// INVADER OUTRO SCREEN FOR 20x4 LCD (7 CCs, 7 unique, plus 2 more but not at the same time)
  clearTheStage(); 
  startPos = 20;
  lcdString = "Hi-Sc rers:  AJR SCR|" 
              "Bb Bb bbbb          "
              "             AR  JSH|"
              "                    "; 
  LCDfontManager();
  setupRow123();
  LCDfontManager();
// Now continue with a brief CC animation:
  startPos = 25;
  for (uint8_t k=0; k < 8; k++) {
    lcdString = "d|I"; // Space Invaders alien, legs in. 
    LCDfontManager();
    delay(500);
    lcdString = "d|O"; // Space Invaders alien, legs out.
    LCDfontManager();
    delay(500);
    }
// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
*/

/*
// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
// INVADER SPLASH SCREEN FOR 20x2 LCD (7 CCs, 7 unique)
clearTheStage();
delay(500);
startPos = 0;
lcdString = "   Space Invaders   |"
            "   Bl    B          "
            "   b-     ABC-      |"
            "   I      UUU       ";
LCDfontManager();
setupRow123();
LCDfontManager();
delay(800);
startPos = 25;
lcdString = "2";  // Add points.
LCDfontManager();
delay(200);
startPos = 26;
lcdString = "5";
LCDfontManager();
delay(400);
startPos = 34;
lcdString = "1";
LCDfontManager();
delay(200);
startPos = 35;
lcdString = "0";
LCDfontManager();
delay(200);
startPos = 36;
lcdString = "0";
LCDfontManager();
delay(1500); 

// INVADER GET READY! SCREEN FOR 20x2 LCD (3 CCs, 2 unique)
clearTheStage();
startPos = 0;
lcdString = "       GET       000"
            "      READY!        ";
LCDfontManager();
delay(1000);
startPos = 37;
lcdString = "111|PPP"; // Stock up on lasers.
LCDfontManager();
delay(1000);
startPos + 37;
lcdString = "_|P"; // Show one laser used/in use: '_'
LCDfontManager();
delay(500);
//while(true) {}

// INVADER GAME SCREEN FOR 20x2 LCD
clearTheStage();
startPos = 0;
lcdString = "                 000|"
            "                    "
            "  LR LR 3 LR LR  _11|"
            "  ss ss P ss ss  PPP";
LCDfontManager();
setupRow123();
LCDfontManager();
for (int8_t row=0; row<4; row++){ // rows 0 to 3
  for (int8_t col=0; col<6; col++){ // relative horizontal positions 0 to 5
    startPos = 0;
    lcdString = "                "; // 16 " ". Update to section clear later
    LCDfontManager();
    if (col % 2) lcdString = invArray[row][0]; else lcdString = invArray[row][1];
    if (row % 2) startPos = 5 - col; else startPos = 1 + col;  
    LCDfontManager();
    delay(600);
  }
}
delay(2000);

// MOTHERSHIP FLY-BY OMITTED (AT LEAST FOR NOW).

// INVADER OUTRO SCREEN FOR 20x2 LCD (7 CCs, 7 unique, plus 2 more but not at the same time)
  clearTheStage(); 
  startPos = 0;
  lcdString = "Hi-Sc rers:  AJR SCR|" 
              "Bb Bb bbbb          "
              "             AR  JSH|"
              "                    "; 
  LCDfontManager();
  setupRow123();
  LCDfontManager();
// Now continue with a brief animation of one of the CCs:
  startPos = 5;
  for (uint8_t k=0; k < 8; k++) {
    lcdString = "d|I"; // Space Invaders alien, legs in. 
    LCDfontManager();
    delay(500);
    lcdString = "d|O"; // Space Invaders alien, legs out.
    LCDfontManager();
    delay(500);
    }
// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
*/

// MISCELLANEOUS TESTS FOR 20x2 LCDs (they also work on 20x4 LCDs):

/*
  clearTheStage();
  startPos = 0; 
  lcdString = "Space is big.|" // 15 CCs, 12 unique. CGRAM overflow --> # # # #
              "Bbbbb bb bbb "
              "         Really big.|"
              "         B    l bbb ";
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  delay(3000);
//while(true){}

  startPos = 0;
  clearTheStage();
  lcdString = "You just won't      believe how vastly,|" // 8 CCs, 8 unique. Bad fontFlags --> @ @
              "    l    l   z                  bbbbbb "; 
  LCDfontManager();
  delay(3000);
//while(true){}

  clearTheStage();
  lcdString = "hugely, mind-bogglingly big it is.|" // 13 CCs, 8 unique.
              "  l  l  bbbb   ll   l l bbb       ";
  LCDfontManager();
  delay(3000);
//while(true){}

  clearTheStage();  
  lcdString = "THE UNIVERSE IS HUGE|" // 17 CCs, 10 unique. CGRAM overflow --> # # #
              "BBB BBBBBBBB BB BBBB"
              "(Douglas Adams HHGG)"; // Second row is plain text (no CCs).
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  delay(3000);
//while(true){}

  clearTheStage(); 
  startPos = 0; 
  lcdString = "A bright LCD display's very easy to read|" // Example with exactly 40 screen characters.
              "     l   BBB    l  l      l    l        ";
  LCDfontManager();
  delay(3000);
//while(true){}
*/


  clearTheStage();
  startPos = 0; 
  lcdString = "   TheaterMaster         SIGNATURE      |" 
              "   BbbbbbbBbbbbb                        ";
  LCDfontManager();
  delay(3000);

  clearTheStage(); 
  startPos = 0;
  lcdString = "   TheaterMaster          Ovation       |" 
              "                          Bbbbbbb       ";
  LCDfontManager();
  delay(3000);

  clearTheStage();
  startPos = 0; 
  lcdString = "   TheaterMaster          Encore        |" 
              "                          Bbbbbb        ";
  LCDfontManager();
  delay(3000);


  clearTheStage();
  startPos = 0;
  lcdString = "CPU:6.9o Z1:00302004DIP:FF-3 Z2:00302004|" // 10 CCs, 8 unique. A sample readout of data.
              "VVV      VV         VVV      VV         ";
  LCDfontManager();
  delay(3000);
//*/

//*
  clearTheStage(); // EMULATION OF A SIX-CHANNEL VU METER FOR 20x2 LCD:
                    // Note: Six bars need up to 7 unique CCs. The VU meter updates at up to 15 Hz!
  startPos = 0; 
  lcdString = " LF cR RF  Ls sB Rs |" // Pop-up this 20x2 LCD template to show the channel names of for 
              " cc  c cc  c   c c  "  // six-channel surround sound VU meter. Small caps channel labels use 8 CCs, 4 unique.
              " 11 11 11  11 11 11 |" // When the VU meter begins again after the names pop-up, in general 6 bars need 7 CCs.  
              " GG GG GG  GG GG GG ";
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  delay(1000); // Pop-up the channel labels for 1 second.
 //
  clearTheStage();  
  for (uint8_t i = 0; i < 30; i++) {
    startPos = 0;
    lcdString = " 22 66 00  77 11 88 |" // Channel dB values: 60, 84, 18, 90, 54, 96 (see Bargraphfont)
                " GG GG GG  GG GG GG "
                " 88 88 33  88 88 88 |" // This example uses 12 CCs, 7 unique. 
                " GG GG GG  GG GG GG ";
    LCDfontManager();
    setupRow123();
    LCDfontManager();
    
    startPos = 0;
    lcdString = " 11 00 00  33 44 22 |" // Channel dB values: 54, 36, (-), 66, 72, 60
                " GG GG GG  GG GG GG "
                " 88 66 00  88 88 88 |" // This example uses 12 CCs, 7 unique. 
                " GG GG GG  GG GG GG ";
    LCDfontManager();
    setupRow123();
    LCDfontManager();
    
    startPos = 0;
    lcdString = " 00 11 00  00 00 22 |" // Channel dB values: 48, 54, 30, 42, 12, 60
                " GG GG GG  GG GG GG "
                " 88 88 55  77 22 88 |" // This example uses 12 CCs, 7 unique. 
                " GG GG GG  GG GG GG ";
    LCDfontManager();
    setupRow123();
    LCDfontManager();
  }
//*/

/*
// Test of a setup screen for a 5.1-channel surround sound processor.
// Note the use of "s" and "c" lowercase characters as stand-ins for small caps.
// Without this work-around most of the following screen would be impossible.
// The best way to avoid a messy substitution (of "C" for "c" and "S" for "s")
// would be to extend the Reverse Caps font with "c" and "s", using the same
// bitmaps as the ordinary Reverse Caps (Update: Already implmented).
// Another approach would be to have reversed version of the big and small
// speakers, and to indicate selection with those.

  clearTheStage();
  startPos = 0;
  lcdString = " LF:K   cR:kx  RF:K  Ls:kx  sB:K   Rs:kx|" //  14 CCs, 6 unique. 3 speakers full range, 3 limited range.
              " VV S    c S   cc S  c  S    c S   c  S "; // The 'x' indicates that a particular small speaker has a cross-over. 
  LCDfontManager();      
  delay(4000); 
*/

/*
// 20x2 LCD test of CC repetition (extreme case):
  clearTheStage();
  startPos = 0;
  lcdString = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF|" //  38 CCs, 2 unique, alternating, except for the last two chars.
              "BVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBB"; 
  LCDfontManager();
  delay(2000); 
//while(true){}
*/

/*
// TEST THE AUTOMATIC REPETITION OF CCs IN A 20x LCD
// To fill a 20x4 LCD with an alternating repeating CC pattern, Font-Pal provides three methods:
//
// (1) Write one long font-formatted String starting at 0 (at 1.2 seconds, this is the fastest
//     method, but has the disadvantage that the source text arrangement is the least similar
//     to the 20x4 screen layout)
  clearTheStage();
  startPos = 0;
  lcdString = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF|" //  80 CCs, 2 unique, alternating.
              "BVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBB"; 
  LCDfontManager();
  delay(1000); 
//while(true){}
*/

/*
// (2) Treat the 20x4 LCD as if a pair of 20x2 LCDs, using two separate 40-character Strings
//     (the source text in this method is somewhat similar to screen layout, but at 1.4 seconds
//     it is 16% slower. NOTE: We cannot use setupRow123() in this method because it would need 
//     to add 40 to the startPos, not 20)
  clearTheStage();
  startPos = 0;
  lcdString = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF|" //  40 CCs, 2 unique, alternating.
              "BVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBB"; 
  LCDfontManager();
  startPos = 40;
  lcdString = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF|" //  40 CCs, 2 unique, alternating.
              "BVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBVBB"; 
  LCDfontManager();
  delay(1000); 
  //while(true){}
*/

/*
// (3) Treat the 20x4 LCD as four 20-character Strings, each written separately (at 1.6 seconds,
//     this method is 30% slower than the first method, but has the advantage that the source
//     text matches the screen layout exactly)
  clearTheStage();
  startPos = 0;
  lcdString = "FFFFFFFFFFFFFFFFFFFF|" //  80 CCs, 2 unique, alternating.
              "BVBVBVBVBVBVBVBVBVBV"
              "FFFFFFFFFFFFFFFFFFFF|" 
              "BVBVBVBVBVBVBVBVBVBV"
              "FFFFFFFFFFFFFFFFFFFF|"
              "BVBVBVBVBVBVBVBVBVBV"
              "FFFFFFFFFFFFFFFFFFFF|"
              "BVBVBVBVBVBVBVBVBVBB"; 
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  delay(1000); 
  //while(true){}
*/

/* 
// TEST OF SCENE ASSEMBLY AND CHANNEL DAISIES FOR A HOME THEATER CONTROLLER:
// Because these variations are run together effectively as one giant 'LCD scene', some lines
// that would normally be needed, are redundant and are commented out. When used with just a single
// clearTheStage() at the beginning, this test is an example of a very long LCD 'scene assembly',
// writing amost 100 scene elements to the LCD. 
  clearTheStage();
  startPos = 4; 
  lcdString = "LR Digital      |" // 3 CCs
              "LL   l          ";
  LCDfontManager();
  
  startPos = 0;
  lcdString = daisy[0];
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  startPos = 24;
  lcdString = "3/2/0  ";  // Plain text
  LCDfontManager();
  delay(1000);

  //clearTheStage();
  //startPos = 4; 
  //lcdString = "LR Digital      |" // 3 CCs
  //            "LL   l          ";
  //LCDfontManager();
  startPos = 0;
  lcdString = daisy[1];
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  startPos = 24;
  lcdString = "2/P/0  ";  // Plain text
  LCDfontManager();
  delay(1000);

  //clearTheStage();
  //startPos = 4; 
  //lcdString = "LR Digital      |" // 3 CCs
  //            "LL   l          ";
  //LCDfontManager();
  startPos = 0;
  lcdString = daisy[2];
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  startPos = 24;
  lcdString = "2/0/0  ";  // Plain text
  LCDfontManager();
  delay(1000);

  //clearTheStage();
  //startPos = 4; 
  //lcdString = "LR Digital      |" // 3 CCs
  //            "LL   l          ";
  //LCDfontManager();
  startPos = 0;
  lcdString = daisy[3];
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  startPos = 24;
  lcdString = "3/1/0  ";  // Plain text
  LCDfontManager();
  delay(1000);

  //clearTheStage();
  //startPos = 4; 
  //lcdString = "LR Digital      |" // 3 CCs
  //            "LL   l          ";
  //LCDfontManager();
  startPos = 0;
  lcdString = daisy[4];
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  startPos = 24;
  lcdString = "3/0/0  ";  // Plain text
  LCDfontManager();
  delay(1000);

  //clearTheStage();
  //startPos = 4; 
  //lcdString = "LR Digital      |" // 3 CCs
  //            "LL   l          ";
  //LCDfontManager();
  startPos = 0;
  lcdString = daisy[5];
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  startPos = 24;
  lcdString = "2/2/0  ";  // Plain text
  LCDfontManager();
  delay(1000);

  //clearTheStage();
  //startPos = 4; 
  //lcdString = "LR Digital      |" // 3 CCs
  //            "LL   l          ";
  //LCDfontManager();
  startPos = 0;
  lcdString = daisy[6];
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  startPos = 24;
  lcdString = "1/0/0  ";  // Plain text
  LCDfontManager();
  delay(1000);

  //clearTheStage(); // Completely clears the HD44780, the CC_id_table and the LCD.
  startPos = 4; 
  lcdString = "No Lock     "; // Show example of input PLL unable to lock on a signal.
  LCDfontManager();
  startPos = 0;
  lcdString = daisy[7];
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  startPos = 24;
  lcdString = "0/0/0  ";  // Plain text
  LCDfontManager();
  delay(1500);

  //clearTheStage(); 
  startPos = 4; 
  lcdString = "LR Digital      |" // 3 CCs
              "LL   l          ";
  LCDfontManager();
  startPos = 0;
  lcdString = daisy[8];
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  startPos = 24;
  lcdString = "3/2/0.1";  // Plain text
  LCDfontManager();
  delay(1000);

  //clearTheStage();
  startPos = 4; 
  lcdString = "LR Digital EX   |" // 3 CCs
              "LL   l          ";
  LCDfontManager();
  startPos = 0;
  lcdString = daisy[16];
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  startPos = 24;
  lcdString = "3/3/0.1";  // Plain text
  LCDfontManager();
  delay(1000);

  //clearTheStage();
  //startPos = 4; 
  //lcdString = "LR Digital EX   |" // 3 CCs
  //            "LL   l          ";
  //LCDfontManager();
  startPos = 0;
  lcdString = daisy[15];
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  startPos = 24;
  lcdString = "3/3/0  ";  // Plain text. Don't forget the two extra spaces to cover "0.1"!
  LCDfontManager();
  delay(1000);

  //clearTheStage();
  startPos = 4; 
  lcdString = "LR Digital      |" // 3 CCs
              "LL   l          ";
  LCDfontManager();
  startPos = 0;
  lcdString = daisy[9];
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  startPos = 24;
  lcdString = "2/P/0.1";  // Plain text
  LCDfontManager();
  delay(1000);

  //clearTheStage();
  //startPos = 4; 
  //lcdString = "LR Digital      |" // 3 CCs
  //            "LL   l          ";
  //LCDfontManager();
  startPos = 0;
  lcdString = daisy[10];
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  startPos = 24;
  lcdString = "2/0/0.1";  // Plain text
  LCDfontManager();
  delay(1000);
  
  //clearTheStage();
  //startPos = 4; 
  //lcdString = "LR Digital      |" // 3 CCs
  //            "LL   l          ";
  //LCDfontManager();
  startPos = 0;
  lcdString = daisy[11];
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  startPos = 24;
  lcdString = "3/1/0.1";  // Plain text
  LCDfontManager();
  delay(1000);

  //clearTheStage();
  //startPos = 4; 
  //lcdString = "LR Digital      |" // 3 CCs
  //            "LL   l          ";
  //LCDfontManager();
  startPos = 0;
  lcdString = daisy[12];
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  startPos = 24;
  lcdString = "3/0/0.1";  // Plain text
  LCDfontManager();
  delay(1000);

  //clearTheStage();
  //startPos = 4; 
  //lcdString = "LR Digital      |" // 3 CCs
  //            "LL   l          ";
  //LCDfontManager();
  startPos = 0;
  lcdString = daisy[13];
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  startPos = 24;
  lcdString = "2/2/0.1";  // Plain text
  LCDfontManager();
  delay(1000);

  //clearTheStage();
  //startPos = 4; 
  //lcdString = "LR Digital      |" // 3 CCs
  //            "LL   l          ";
  //LCDfontManager();
  startPos = 0;
  lcdString = daisy[14];
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  startPos = 24;
  lcdString = "1/0/0.1";  // Plain text
  LCDfontManager();
  delay(1000);

  //clearTheStage();
  startPos = 4; 
  lcdString = "dts             |" // 3 CCs
              "LLL             ";
  LCDfontManager();
  startPos = 0;
  lcdString = daisy[0];
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  startPos = 24;
  lcdString = "3/2/0  ";  // Plain text
  LCDfontManager();
  delay(1000);

  //clearTheStage();
  //startPos = 4; 
  //lcdString = "dts             |" // 3 CCs
  //            "LLL             ";
  //LCDfontManager();
  startPos = 0;
  lcdString = daisy[8];
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  startPos = 24;
  lcdString = "3/2/0.1";  // Plain text
  LCDfontManager();
  delay(1000);
  
  //clearTheStage();
  //startPos = 4; 
  //lcdString = "dts             |" // 3 CCs
  //            "LLL             ";
  //LCDfontManager();
  startPos = 0;
  lcdString = daisy[5];
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  startPos = 24;
  lcdString = "2/2/0  ";  // Plain text. DTS audio 'CD' format 4 full-range channels. 
  LCDfontManager();
  delay(1000);

  //clearTheStage();
  startPos = 4; 
  lcdString = "dts ES          |" // 3 CCs
              "LLL             ";
  LCDfontManager();
  startPos = 0;
  lcdString = daisy[15];
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  startPos = 24;
  lcdString = "3/3/0  ";  // Plain text
  LCDfontManager();
  delay(1000);

  //clearTheStage();
  //startPos = 4; 
  //lcdString = "dts ES          |" // 3 CCs
  //            "LLL             ";
  //LCDfontManager();
  startPos = 0;
  lcdString = daisy[16];
  LCDfontManager();
  setupRow123();
  LCDfontManager();
  startPos = 24;
  lcdString = "3/3/0.1";  // Plain text
  LCDfontManager();
  delay(1000);
*/

} // ------END------
