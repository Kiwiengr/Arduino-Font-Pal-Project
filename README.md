The Font-Pal project is developing a font manager for displaying custom fonts on LCD character displays that use the Hitachi HD44780 
and ultimately plans to transform the font manager into an Arduino library function. 
# Arduino Font-Pal README file
Copyright (c) 2024 Alastair Roxburgh

(Abstract: Font-Pal recreates the functionality of an original 68HC11 stack-frame assembly language program named SCREENS, devised in 1997 by Alastair Roxburgh & Sunil Rawal for the EOS series of TheaterMaster digital home theater audio processors. Written in Arduino C++, Font-Pal uses Strings, chars and arrays of struct to create a custom font manager for 16x2, 20x2, and 20x4 LCDs
based on the Hitachi HD44780 chip.)

Note:
Developed expressly for the Arduino Mega platform, Font-Pal reproduces most of the functionality of its 1977 68HC11 predecessor. However, the algorithms are only remotely similar.

Font-Pal is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation version 3 of the License.

Font-Pal is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY, without even the implied warranty of MECHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Public License for more details.

You should have received a copy of the GNU General Public License with Font-Pal. If not, see http://www.gnu.org/licenses/.

See the license.txt file for further licensing & copyright details.

## SUMMARY
Font-Pal is a font manager for Arduino projects using Hitachi HD44780-based LCDs and is so-named as a more easily pronounced version of Font-Palooza, a handle inspired by (a more challenging to pronounce) Lollapalooza, the famous recurring music festival first held in 1991. Since then, the word "palooza" has been used so often that it has entered the mainstream language as a stand-alone word, a neologism. Indeed, following in Lollapalooza's footsteps, "palooza" is now defined as an event or thing that aspires to be "an extraordinary or unusual thing, person, or event; an exceptional example or instance" (dictionary.com). Some of my favorite examples are Hula Palooza, Datapalooza, law-LA-palooza, St. Lou-a-palooza, and MINE-a-palooza (sometimes hyphenated, sometimes not; sometimes preceded by the "a" from Lolla). OED Online traces Lollapalooza in its various spellings back to 1904 but, strangely, makes no mention of Lala Palooza, the name of the female protagonist in Pulitzer prize winner Rube Goldberg's 1936-1939 comic strip of the same name.

Hence, with apologies to Douglas Adams, Font-Pal hopes it will be seen as impressive and wholly remarkable, even if not as wildly popular and in-your-face as the asteroid named Arthurdent (asteroid 25924).  ;-)

Written in Arduino C++, Font-Pal creates a custom font manager using a mix of chars, Strings, and arrays of structs. Tested on Arduino Mega and Arduino UNO R4, It recreates the functionality of an original 68HC11 stack-frame assembly language program devised in 1997 by Alastair Roxburgh and Sunil Rawal for the ground-breaking EOS series of TheaterMaster digital home theater audio processors.

Although this new implementation mirrors many of the capabilities and structure of its 68HC11-based predecessor, apart from using a similar character bitmap database, many of the algorithmic details are different. Interestingly, whereas the 68HV11E1 microcontroller used in EOS TheaterMasters is an 8-/16-bit 2 MHz CISC-based design, the Arduino's 16 MHz 8-bit RISC-based ATmega2560 runs at a
similar speed overall, the bottleneck being the modest speed of the Hitachi HD44780 controller chip in typical LCDs, not to mention the relatively slow response of typical Okaya STN Transflective LCDs (which can take 150 ms to go from clear to full black when a typical character is displayed and 300 ms to fade to clear when a space is displayed).

### TABLE OF CONTENTS:

  INTRODUCTION

  USING FONT-PAL

  FONT FORMATTING OF LCD DISPLAY STRINGS:

    •	DISPLAYING PLAIN TEXT

    •	MORE HINTS ON HOW TO USE FONT-PAL

    •	THE FOLLOWING METHOD IS NOT RECOMMENDED FOR DOUBLE ROW CC GRAPHICS

    •	ERROR REPORTING

    •	GENERAL POINTS ABOUT HITACHI HD44780-BASED LCD DISPLAYS

  NOTES:
  
    •	A SUMMARY OF FONT-PAL FORMATS AND COMMANDS
    
    •	LCDfontManager() Implementation Notes


## INTRODUCTION
Font-Pal for the Arduino platform allows the app designer to bypass much of the frequently complex chore of custom character (CC) and font management associated with Hitachi HD44780 character-based LCDs. In its essentials, Font-Pal automates the management of CGRAM, a scarce memory resource internal to the HD44780 LCD controller chip that stores the bitmaps of up to eight CCs. Font-Pal reduces some of the barriers to programming complex and varied sequences of CCs. Working behind the scenes, Font-Pal loads and unloads HD44780 CC bitmaps in real-time, according to the moment-by-moment need of software applications to have effective alpha-numeric displays with graphical enhancements. Whether the application is a simple hobby video game or something more serious, such as an embedded controller in a home theater receiver or a home control system, a big part of Font-Pal's value proposition is that it separates the chore of font management from the application code, giving the application programmer more time to develop application features without being bogged down by the tedious task of manually managing CCs and CGRAM memory. Leveraging both the Arduino String class (similar to C++ std::string) and char data types, as well as their respective methods, Font-Pal optimizes brevity and clarity while maintaining sufficient flexibility and efficiency.

When Font-Pal loads a CC into CGRAM, it stores a tag to that CC in every data display memory (DDRAM) location that will display the CC. When parts of the screen are updated with new CCs, Font-Pal first erases the relevant locations in CGRAM. If this happens to erase a CC still in use in a different part of the screen, and as long as it does not exceed the limit of eight CCs, the CC will be reloaded into CGRAM.

Consider how much of an all-around improvement Font-Pal can produce:

1.	  Reduced application development time,
2.	  Improved application quality,
3.	  Nicer-looking and more legible displays,
4.	  Better LCD utilization through optimized CC automation.

Such improvements will not necessarily be subtle and may also defer,
indefinitely, the need to move to a bit-mapped display and faster
microprocessor.

Several examples of Font-Pal use follow:

### EXAMPLE (1):
Font-Pal can quickly turn a 20x2 LCD into a 2- to 10-channel VU meter, simultaneously displaying up to 16 levels per channel at 6 dB per step. If we reserve the bottom bar for zero signal and ignore the 6 dB gap between the two LCD rows, we obtain a total range on each channel of 15*6 dB = 90 dB, which can be updated twice a second. Indeed, by using the two LCD rows separately, we can display up to 20 channels with half of the vertical resolution. In such extreme cases of power through the repetition of bitmaps, eight static bitmaps stored in the CGRAM are stretched to as many as twenty simultaneously displayed locations on the LCD, as in the following examples of symmetrical VU mater layouts:
```
                     xxxxxxx  xxxxxxx     2 channels
                   xxxxxx xxxxxx xxxxxx   3 channels      
                    xxxx xxxx xxxx xxxx   4 channels
                   xxx xxx xxxx xxx xxx   5 channels
                   xx xx xxx  xxx xx xx   6 channels
                   xx xx xx xx xx xx xx   8 channels
                    x x x x xx x x x x    9 channels
                   x x x x x  x x x x x   10 channels
```
where 'x' represents a single bar-font character. The following diagram shows a VU meter for ten audio channels constructed using a 20x2 char LCD. For 6 dB steps, converting from linear amplitude to logarithmic (dB) amplitude is straightforward: the audio DSP averages the observed position of the highest 1-bit in arithmetically positive audio samples (typically 16- to 24-bit words). It does not matter if the number representation is integer or fractional. If the VU meter processes five values per second, an appropriate averaging period is about 200 ms or 10,000 audio samples. If you require a peak-reading VU meter, display the position of the highest bit observed during the same period rather than the average. You can also slide the dB scale up or down in 6 dB steps to set the 0 dB wherever you want. The diagram (below) shows amplitudes of 0, 0, 60 dB, 66 dB, 18 dB, 78 dB, 30 dB, 36 dB, 96 dB, and 0, where '0' (not defined on a logarithmic scale) represents zero signal. This example illustrates how you can stretch the eight CGRAM locations to create a VU meter for up to 10 channels on a 20x2 LCD:
```
                   +--------------------+
                   |     2 3   5     8  |
                   | 1 1 8 8 4 8 6 7 8 1|
                   +--------------------+
```
where the numeral signifies the height in pixels of a block-shaped CC, a '1' alone in a channel (i.e., the bottom row of pixels only) represents zero signal, leaving a range of 16 x 6 dB = 96 dB (including the 1-pixel-height inter-row gap of 6 dB). You can find an example of this type of bar graph in the optional Font-Pal splash screen. Also included in Font-Pal is a utility function, printFonts(), which can help you verify the correctness of the font bitmap tables after you've made changes.

In the vertical bar graphs just described, the entire resource of eight CCs is dedicated to this one use. Nevertheless, we can choose the number of channels and bar widths because these take advantage of the freedom to repeat CCs to build bars of any suitable widths. This way, we can create displays that compel the eye of the beholder, creating the impression that there are more than eight individually programmable CCs. I need to point out that the Font-Pal LCD manager avoids methods that aim to trick the eye through CC animation, which can lead to less-than-satisfactory results due to the relatively slow response time of STN (super-twisted nematic) transflective LCD technology. Font-Pal's bar graph characters have a central gap to hide the distracting presence of the inter-character gap when the bar width is greater than one character. This gap also allows for flexibility in setting the width of bars and using mixed bar widths while maintaining the same look of the bars. For example, if we construct three bars having widths of one, two, and three characters, respectively, with heights of 1, 3, and 2 pixels, they will look something like:  
```
                              XX XX XX XX      XX XX XX XX XX XX
                              XX XX XX XX      XX XX XX XX XX XX
             XX XX XX XX      XX XX XX XX      XX XX XX XX XX XX
```
rather than:
```
                                               XXXXX XXXXX XXXXX
                              XXXXX XXXXX      XXXXX XXXXX XXXXX
             XXXXX XXXXX      XXXXX XXXXX      XXXXX XXXXX XXXXX
```
The split bar design of the top example makes the bars look more uniform.

### EXAMPLE (2):
A home theater processor's LCD screen might look like this:
```
                   +--------------------+
                   |vOv LR Digital 5.1  |
                   |^Q^ D1:Blu  X -15 dB|
                   +--------------------+
```
where the eight unique CCs are marked as vO^QLRXg, for a total of ten CCs on screen. The vOv and ^Q^ represent a "channel daisy" that indicates which channels are in use with the current signal source, requiring four unique CCs. The "LR" is two CCs forming a Dolby "Double-Dee" logo; the "g" is an improved lowercase g with a true descender, and the "X" is an equalization indicator, a single CC in the shape of 'E/Q'.

The Channel ("C") font produces 6.1 channel layouts similar to the following:
```
      *                                  C            LF  =  Left front
  *       *                         LF       RF       C   =  Center front 
      *       correspond channels:      SUB           RF  =  Right Front
  *       *                         LS       RS       LS  =  Left Surround
      *                                  ES           ES  =  Extended Surround
                                                      RS  =  Right Surround
                                                      SUB =  Subwoofer
```

### EXAMPLE (3):
A micro-space-invaders game layout might look like this:
```
                   +--------------------+
                   | x x x x x       000|
                   |  /\ /\ ! /\ /\  _!!|
                   +--------------------+
```
where the five on-screen CCs are marked x/!, representing an invader (repeated five times), the "/" is a pair of CCs that has the shape of a shield, while "!" is a CC in the shape of a laser. The invaders use ten different CCs (five with legs in and 5 with legs out) that load in sequence as the waves of aliens descend ever closer. Arduino C++ code for constructing the above screen (I have added comments about the various items in this code fragment):
```
startPos = 0; // The position (0-39) on the screen where the String will be written.
lcdString = "a a a a          000|" // No ';' "|" marks the end of a font-formatted String
            "I I I I             "  // No ';'
            " LR LR 3 LR LR   _11|" // No ';' Another "|" because this is a 2-row screen-write.
            " ss ss P ss ss   PPP"; // Yes ';' marks end of C++ statement.
LCDfontManager(); // This writes the first LCD row.
setupRow2(); // Housekeeping function needed...
LCDfontManager(); // ahead of writing the second row of the 2-row String.
```

### EXAMPLE (4):
A screen example that might look at home in a home theater audio processor:
```
                   +--------------------+
                   |LF:O   CR:ox  LR:O  |
                   |LS:ox  SB:O   RS:ox |
                   +--------------------+
```
where the LF, CR, LR, LS, SB, and RS use a mixture of lowercase ('c' and 's') and small-caps CCs (L, F, R, B) to render a larger set of custom small-caps using only four CCs. Together with speaker-shaped CCs (large and small, denoted here as 'O' and 'o') and a regular lowercase 'x' indicating channels with small speakers that cross over the low frequencies to the subwoofer channel, a readout that helps to simplify the speaker and base management setup for a home theater processor. This screen uses fourteen CCs, six unique, but, as a result of repetition, it gives the impression that there are more than that.

## USING FONT-PAL
### FONT FORMATTING OF LCD DISPLAY STRINGS:
This routine parses font-encoded Strings, N characters at a time, loading the relevant custom characters before sending the processed String to a Hitachi HD44780-compatible LCD module for display.

Example String (where "_" represents an ASCII space 0x20, but you would type an actual space character):
```
               clearTheStage();
               startPos = 0; 
               lcdString = "Large LCD Display|"
                           "   l  BBB    l  l";
               LCDfontManager(); 
```
There can be up to 40 display characters before the '|' marker character, with the corresponding font flags in the following row, which is convenient when constructing a display String on the fly. The VU meter capability is discussed later. In the meantime, here is a more normal string that fills all 40 locations on a 20x2 LCD:
```
clearTheStage();
startPos = 0
lcdString = "This long String fills two lines exactly|"  // 2 CCs, 2 unique.
            "        l      l                       l";
LCDfontManager(); 
```
The number of characters after the "|" must equal the number before. Counting is zero-relative, so the marker character is at position 40. Thus, the number of fontChars before the "|" is 40, and there are 40 fontFlags after the "|". A space in the second line indicates that the LCD's default ROM-based characters will be used. The total number of characters in this string is 81, of which only the first 40 get displayed (after CC substitutions).

Important Note: The Font-Pal LCD font manager expects ALL font-formatted Strings to have the second part marked by "|" and containing the fontFlags.

### DISPLAYING PLAIN TEXT:
In addition to displaying font-formatted strings, Font-Pal also supports un-font-formatted Strings, a.k.a. plain text. It can display a mixture of the two. However, if plain text suffices for a particular LCD field and is 100% plain (i.e., no font flags or "|" font marker character), the text is displayed more quickly. Please look at the examples below for more guidance on using this feature.

### MORE HINTS ON HOW TO USE FONT-PAL:
You can copy and paste the following Font-Pal examples into your Arduino IDE or uncomment them in the void loop() section of the main .ino file:

(a) An example of displaying a plain text String at position 25 on the LCD, equivalent to placing the text starting at position 5 in the second row. Note: If we intend to add a new String to an existing LCD 'scene', we will omit ClearTheStage ().
```
               clearTheStage(); // This line may not be needed (see note)
               startPos = 25; // Allowable range is 0-39
               lcdString = "D2:DVD"; // Plaintext example (no font encoding)         
               LCDfontManager();
```
The variable startPos selects the position on the LCD where you want to display the text. Strings positioned to extend beyond the end of row 0 of the LCD wrap around onto row 1. Strings extending past 40 characters (i.e., the screen size) are truncated. The variable startPos has a default value of 0 and can go as high as 39.

(b) The best way to blank out only part of the LCD is to write a blank plain-text String:
```
               // Write six spaces to the LCD, starting at position 8:   
               startPos = 8; 
               lcdString = "      "; // <-- Note: no '|' marker. 
               LCDfontManager(); 
```
(c) An example of displaying a String at position four that has mixed font-formatted text and plain text:
```
               clearTheStage();
               startPos = 4; 
               lcdString = "LR Dolby digital|" // <-- Note the '|' marker, and no ';'
                           "LL     l   l    "; // Need the ';' here, though!
               LCDfontManager(); 
```
(d) To ensure that a new character string written to the LCD completely overwrites any previous write to that field, it is simple to pad an item with spaces, illustrated by the extra space in the following bold-formatted "ON" String. Without this extra space, the last "F" in "OFF would still be on the LCD, giving 
```
		"ONF";
		"ON |BB "; and "OFF|BBB"; 
```
(e) Whenever beginning a new LCD 'scene', the best way to clear the LCD and all CCs stored in the CGRAM, of the LCD is to 'clear the stage':
```
		clearTheStage(); // Do this before building a new 'scene'
```
On the other hand, if we need to clear all or part of the LCD without clearing the relevant CCs out of CGRAM, we can write some plain-text spaces. The following writes eight plain-text spaces beginning at screen position 10:
```
               startPos = 10; 
               lcdString = "        "; // 8 plain-text spaces beginning at 10.
```
Note: This is simpler and takes much less time than the following alternative approach of using a font-formated string of spaces to write over the same field:
```
               startPos = 10;
               lcdString = "        |" // 8 spaces beginning at 10.
                           "        ";
```
or:
```
               startPos = 10;
               lcdString = "        |        "; // 8 spaces beginning at 10.
```
(f) Most useful for shapes that take up two lines (e.g., the channel 'daisy' CC patterns defined in the font library) is the ability to break up the pattern into two short Strings of equal length rather than overwrite the rest of the display with spaces. These lcdStrings differ from the standard lcdString in the use of two "|" markers, one for each row:
```
               startPos = 0;
               lcdString = "232|CCC"
                           "1e1|CCC";
```
If you prefer, this may be written in the following alternative (equivalent) form:
```
      startPos = 0;
      lcdString = "232|" // Make sure all four Strings have the same length.
                  "CCC"
                  "1e1|"
                  "CCC";
```
However, to make either of these double-row examples work, you must use two calls to LCDfontManager(). I have omitted the optional call to clearTheStage() because if the LCD already displayed a different 'daisy', this new one would rewrite it, leaving any other text on the LCD unchanged. It is important to note that the 'daisy' examples all use four unique CCs, leaving only four for any other lcdStrings that are part of this 'scene'.
Either:
```
               // Recommended for formatting double-row CC graphics:
               clearTheStage();
               startPos = 0;  
               lcdString = "232|CCC" 
                           "1e1|CCC";
               LCDfontManager();
               setupRow2();
               LCDfontManager();
```
Or:
```
               // Recommended for formatting double-row CC graphics:
               clearTheStage();
               startPos = 0;
               lcdString = "232|"
                           "CCC"
                           "1e1|"
                           "CCC";
               LCDfontManager();
               setupRow2();
               LCDfontManager();
```
Without the setupRow2() function and the second call to LCDfontManager(), the second row ("1e1|CCC") would be ignored and not get printed.

### THE FOLLOWING METHOD IS NOT RECOMMENDED FOR DOUBLE-ROW CC GRAPHICS:
Combining both rows of characters into a single string that wraps onto the second row of the LCD fails to be as helpful; it fails to mimic the LCD layout and cannot avoid overwriting other items on the LCD. Although it bypasses the need for the setupRow2() helper function and a second call to the LCD font manager, it leaves you with the need to pack out lcdString with enough spaces to push the second-row characters ("1e1|CCC" in this example) past the end of the first row and onto the second row, which (depending on the value of startPos) may write over parts of LCD screen you wish to keep. However, unless that is your intention, the two "|" marker formats shown above largely avoid using space characters to format double-row graphics correctly, and this is the preferred method.
```
               // The following is not recommended for double-row CC graphics:
               startPos = 0;
               lcdString = "232                 1e1|CCC                 CCC";
               LCDfontManager();
```

### ERROR REPORTING:
Various error conditions are indicated by the appearance of the following special characters on the LCD (which the controller displays in place of every requested but unavailable custom character):
```
   "#"   ---   CGRAM overflow (more than eight unique custom characters)
   "@"   ---   Bad font-char or bad font-flag
```

### GENERAL POINTS ABOUT HITACHI HD44780-BASED LCD DISPLAYS:
The LCD is used write-only, with all screen editing in the screenImage RAM buffer that is then copied to the LCD by the LCDfontManager() function. A significant part of any digital controller design that uses a Hitachi HD44780-based LCD is consideration of the font-formatting design, juggling the timing of what is shown on the LCD and when, given the scarcity of CGRAM locations in the HD44780. This controller chip can display only eight unique custom characters (CCs), mitigated by the ease with which any CC can be repeated on-screen up to the limit of the LCD (e.g., 40 characters in a 20x2 LCD).

With due care during the design phase of a project (such as the EAD EOS TheaterMasters), the limitation on the number of unique CCs can be made to look like many more. Easy to overlook but helpful in this regard are the following points:

(i) Lowercase ROM characters scouvwxz are sufficiently shape-similar to the custom smallcaps font in the Font-Pal package that they can effectively act like eight more CCs.

(ii) By carefully choosing your onscreen words and names, Font-Pal can aid you in minimizing your use of custom characters versus the use of built-in ROM characters, especially in the all-important 'splash screen' that uniquely identifies a product or system:

Splash screen example 1: TheaterMaster SIGNATURE (eight unique CCs, nine unique ROM chars)
```
                 clearTheStage(); startPos = 3;   
                 lcdString = "TheaterMaster|BbbbbbbBbbbbb"; // Bold and lowercase bold
                 LCDfontManager(); startPos = 25; 
                 lcdString = "SIGNATURE"; // Plain text
                 LCDfontManager(); 
                 delay(3000);
```
or
```
                 clearTheStage(); startPos = 3; 
                 lcdString = "TheaterMaster         SIGNATURE|" 
                             "BbbbbbbBbbbbb                  "; 
                 LCDfontManager();
                 delay(3000);
```                    
Splash screen example 2: TheaterMaster Ovation (seven unique CCs, eight unique ROM chars)
```
                 clearTheStage(); startPos = 3;   
                 lcdString = "TheaterMaster          Ovation|"
                             "                       Bbbbbbb";
                 LCDfontManager(); 
                 delay(3000);

```
Splash screen example 3: TheaterMaster Encore (six unique CCs, eight unique ROM chars)
```
                 clearTheStage(); startPos = 3;   
                 lcdString = "TheaterMaster          Encore|"
                             "                       Bbbbbb";
                 LCDfontManager(); 
                 delay(3000);
```
Splash screen example 4: 8800Pro (eight unique bignum CCs, three unique ROM characters)
```
                 clearTheStage(); startPos = 5;   
                 lcdString = "ABABABAB   |88880000   "   // Double-row Strings must
                             "CDCDCDCDPro|88880000   ";  // be of equal length!
                 LCDfontManager(); setupRow2(); LCDfontManager();
                 delay(3000);
```
Splash/Feature screen example 5: (six unique CCs, nine unique ROM characters)
```
                      clearTheStage(); startPos = 1;   
                      lcdString = "Reference CinemaTM    & Cinema 7.1TM|"
                                  "B         B     SS      B      B BSS";
                      LCDfontManager(); 
                      delay(3000);
```

(iii) Letters in common between font-enhanced words come at no additional CGRAM cost.

(iv) Although CGRAM limits unique custom characters (CCs) to eight, they can be repeated up to the size of the display (e.g., 32 CCs for a 16x2 LCD, 40 for a 20x2 LCD, or 80 for a 20x4 LCD).

(v) Eight CCs are sufficient to code multi-channel vertical bar graphs with 16 steps and horizontal bar graphs with up to 100 steps.

(vi) Sometimes, it's feasible to design multi-character CCs that hide the one-pixel gap between LCD characters and rows by including a mid-character gap in the CCs. Examples of this are provided in the bar-graph font. (Okaya and many similar 16x2 or 20x2 LCDs have a one-pixel gap between rows and columns).

(vii) Multi-character CCs will often look better if the one-pixel row/column gaps are added in the bitmap editor to preserve the geometry. This makes multi-character CCs look like they are being viewed through 1-pixel grid lines spaced five pixels horizontally and eight vertically. (Okaya and many similar 16x2 or 20x2 LCDs have a one-pixel gap between rows and columns). 

(viii) Use the "#" and "@" error flags to help you design screen layouts free from CGRAM overflow and font errors.

## NOTES:
During this development, I discovered that Arduino variables of type String and built-in functions that process them often have a problem with bytes or characters with the value 0x00, i.e., byte(0). This is a carry-over from the C (and C++) use of the \0 null character (0x00), the end-of-string marker in traditional C-strings, and even though the relatively new String type does not use such markers, my attempts to print Strings containing 0x00 sometimes had problems. Perhaps the Hitachi HD44780 designers already anticipated this problem because, to their credit, they arranged for a set of shadow addresses, allowing us to access those same eight CC bitmap locations in the chip's CGRAM at 0x00-0x07 or 0x08-0x0f (BTW, that OR is an inclusive-OR). Therefore, where it matters in this program, we number the HD44780 LCD controller's CGRAM locations from 0x08 to 0x0f (8 to 15). However, because no such duplicate addressing exists for the various arrays, all of which start at index 0, make sure to add 8 to all zero-relative custom character (CC) CGRAM pointer values when assembling a 'scene' (a name used here to describe an LCD that is made up of two or more small Strings that are assembled into the screenImage String being written to the LCD.

Example of Arduino C++ code for displaying two aligned 20-character Strings:
```
             clearTheStage();
             startPos = 0;
             lcdString = "Hi-Sccrers:  AJR SCR|" // Begins at startPos on the LCD.
                         "bb bbObbbb          "
                         "             AR  JSH|" // Begins at startPos + 20 on LCD.
                         "                    ";
             LCDfontManager();
             setupRow2();
             LCDfontManager();
```
Note that all such two-row strings have two '|' font markers. While the same display may be constructed using a single String, the lack of inherent screen layout makes verification more difficult despite fewer function calls:
```
           clearTheStage();
           startPos = 0;
           lcdString = "Hi-Scorers:  AJR SCR             AR  JSH|"
                       "bB bBOBBBB                              ";
           LCDfontManager();
```
Behind the scenes, after custom font processing, lcdString overwrites screenImage, which, in turn, is written to the LCD. Whichever way you edit your Strings, the resulting LCD screen layout will be similar to the following:
```
               +--------------------+
               |Hi-Scorers:  AJR SCR|
               |             AR  JSH|
               +--------------------+ 
```

## A SUMMARY OF FONT-PAL FORMATS AND COMMANDS

1. Plain text (1-40 chars) starting at position 0-39. Example:
```
           startPos = 5; lcdString = "Hello World!"; LCDfontManager();
```

2. Font-formatted text and CCs (1-40 chars) starting at position 0-39. Formatted text must end with '|'. The fontChar and fontFlag parts of lcdString must match. Using two lines as shown allows you to check the font formatting visually. Example:
```
           startPos = 24; lcdString = "Nice day for it!|"
                                      "b      L        ";
           LCDfontManager();
```

3. Optional command to clear font formatting before overwriting the LCD with a new font-formatted string. This is useful when creating an LCD 'scene' from multiple lcdStrings:
```
clearTheStage(); 
```

4. Font formatting of double-height aligned blocks of text and CCs. This is particularly useful when creating 'big nums' or other CC groupings. Every double-height lcdString must have precisely two '|' marker characters. The string lengths must match. Due to the HD44780 limit of eight CCs, repetition of CCs is your friend because, for example, a single CC can be repeated 40 times to fill the display at no cost. Bar graphs, in particular, can take full advantage of this. Example:
```
               clearTheStage(); 
               startPos = 0;
               lcdString = "232|"
                           "CCC"
                           "1e1|"
                           "CCC"; 
               LCDfontManager();
               setupRow2();
               LCDfontManager();  
```

5. If your LCD is the STN (super-twisted nematic) transflective type, and your display data changes several times a second, you may need to add delays to ensure complete visibility. Although providing excellent sunlight visibility at low cost, STN LCDs can take 150 ms to go from clear to full black and 300 ms to fade to clear. To make your display easy to read under all light conditions, you may need to wait out these times by adding delays of 100 ms or more. Experimentation is your best guide.

6. Dynamic displays such as bar graphs require lcdString to be constructed on the fly, e.g. using C++ built-in String functions.

### The Font-Pal LCDfontManager() - Liquid Crystal Display Font Manager Implementation Notes:

(1) Scan lcdString to detect '|' markers...

(2a) Perform an interleave merge of fontChar & fontFlag sections of lcdString, excluding the '|' marker, e.g., "LR DoobyoD|ll BBB LBB" --> "LlRl DBoBoBb yLoBDB"), and also processes the top row of double-row symbols (e.g., "Test|B CASE|BBBB|" --> "TBe s t "):

(3) We are nearly ready to copy the merged lcdString into screenImage starting at startPos. Still, first, we need to clean up the CC_id_table, removing any entries that will be overwritten by the current lcdString, which is necessary to maximize the tiny eight CC CGRAM resource. Here are the details of how that is done: Parse the even characters in merged_screenImage for CC codes that will be overwritten by a newly merged lcdString, beginning at startPos, and ending at startPos + lcdString.length() -1. As we discover these CCs in the relevant section of screenImage, we will delete them from the CC_id_table. And because CCs in screenImage are codes in the range 0x08-0x0f, that is the range we will look for. The tricky part of this parsing is to take into account that just like merged_lcsString, screenImage also uses the merged format of screenImage, wherein the relevant fontChars are at even locations, 0, 2, 4, 6, ... We can obtain even addresses by using a simple arithmetic left-shift (<< 1). However, we don't do this for CC_id_table (a table that contains a list of the CCs loaded into CGRAM of the LCD's controller chip). Given that C++ arrays are 0-relative, the CC_id_table addressing is 0x00 to 0x07, but because 0x00 (\nul) has particular use in C and C++ for marking the end of c-char character strings, we cannot use 0x00 as a CC code value in String function and char processing. Luckily, the HD44780 LCD controller provides a set of shadow addresses for the CGRAM: 0x08-0x0f, obtained by adding 8 to the 0x00-0x07 addresses. This avoids treating the 0x00 CC code value as a special case. However, since, as mentioned above, C and C++ arrays start at 0 and proceed up from there, this program uses both ranges, 0x00-0x07 and 0x08-0x0f, as and when necessary. Typical contents of CC_id_table may look like this:
```
     CC_id_table[0] = "2C"; // ==> CC code = 0x08 = 0 + 8 = 8  ("2C" fonChar,fontFlag)
     CC_id_table[1] = "3C"; // ==> CC code = 0x09 = 1 + 8 = 9
     CC_id_table[2] = "1C"; // ==> CC code = 0x0a = 2 + 8 = 10
     CC_id_table[3] = "eC"; // ==> CC code = 0x0b = 3 + 8 = 11
     CC_id_table[4] = "dL"; // ==> CC code = 0x0c = 4 + 8 = 12
     CC_id_table[5] = "tL"; // ==> CC code = 0x0d = 5 + 8 = 13
     CC_id_table[6] = "gl"; // ==> CC code = 0x0e = 6 + 8 = 14  (g true descender)
     CC_id_table[7] = "sL"; // ==> CC code = 0x0f = 7 + 8 = 15
```
If our parse finds, e.g., a CC code of 6 in the merged_screenImage overwrite section, this refers to the gl entry in the table, currently stored at CC_id_table[6]. We delete it from the table with
Then, after lcdString is overwritten at its startPos in the merged_screenImage, any new CCs in lcdString are saved into free locations in CC_id_table. CGRAM overflow can occur if there are more than eight unique custom characters (CCs). This condition is signalled with one or more "#" flags on the LCD.
Continuing, we parse the to-be-overwritten section of merged_screenImage and delete any prior CCs found with a fontChar between 0x08 and 0x0f, with fontFlag = " ".

(Now parse screenImage for CC flags, load the CC bitmaps to the LCD chip, and place CGRAM_ptrs in screenImage overwriting the fontChars. Use CC_id_table to keep track of the limit of only 8 CCs! Font-Pal then processes the merged lcdString into screenImage at startPos, inserting CCs and error flags as needed.
Finally, Font-Pal prints all EVEN characters, 0,2,4,6,..., in screen_image to the LCD.
Note: STN transflective LCDs typically transition relatively slowly (150 ms transparent to 90% black, and 300 ms black to 90% transparent), requiring a delay of about 200 ms before the next LCD screen write, a time best determined by experiment.

# A List of Font Letter Names and Font Characters
```
Font  Font Name     Characters                           Size
 G = bargraphfont   0abcLR!87654321                       15 
 0 = big0font       ABCD                                   4 
 1 = big1font       ABCD                                   4  AB A'B' 
 2 = big2font       ABCD                                   4  CD C'D' 
 3 = big3font       ABCD                                   4  A maximum of two bignums digits! 
 4 = big4font       ABCD                                   4 
 5 = big5font       ABCD                                   4 
 6 = big6font       ABCD                                   4 
 7 = big7font       ABCD                                   4 
 8 = big8font       ABCD                                   4 
 9 = big9font       ABCD                                   4 
 S = symbolfont     DSTMH><^vuds_1234KkLQnNbCF            26      
 B = Boldfont       ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789  36  
 b = boldlcfont     abcdefghijklmnopqrstuvwxyz            26  
 l = lowercasefont  gjpqym                                 6  
 c = smallcapsfont  ABDEFGHIJKLMNPQRTUY                   19  Use built-in ROM cosvwxz for smallcaps COSVWXZ   
 f = smlfrequfont   kHz                                    3  
 v = smlrevcapsfont BCFLSTR                                7  
 V = revcapsfont    ABCDEFGHIKLOPRSTUVXYZ0123456789=:     33  No JMNQW.  '=' is 5x8 pixel block.
 C = channelfont    241dca5b3ef6xyzuvwjkl                 21  2...6 are channel daisies, xyz, ...jkl are 3-char triangular shapes.
 L = logofont       LRdtsHDC0123456                       15  
 O = outvaderfont   abcd                                   4 
 I = invaderfont    abcd                                   4 
 P = laserfont      12345_                                 6 
 E = kapowfont      12345                                  5 
 s = shieldfont     LR                                     2 
 U = UFOfont        ABCDIJKLQRSTabcdijklqrst              24  
```
