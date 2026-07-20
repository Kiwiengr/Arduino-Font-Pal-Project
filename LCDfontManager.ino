/*----------------------------------------------------------------*/
/* LCDfontManager() - Font-Pal Liquid Crstal Display Font Manager */
/*----------------------------------------------------------------*/
void LCDfontManager() {
  bool fontEncoded = true;
  uint8_t* gBitmap;
  String merged_lcdString;
  screenImage.reserve(screenLength);
  
  // %%%%% BEGIN FONT PROCESSING OF THE CURRENT lcdString...
  // ==[Step 1]==================== 
  // SCAN lcdString TO DETECT PRESENCE OF '|' FONT MARKERS... 
  int8_t marker_idx = lcdString.indexOf('|');
  if (marker_idx == -1) fontEncoded = false; // If lcdString is plain text, print it more-or-less directly...
  
  // ==[Step 2]==================== 
  // PERFORM AN INTERLEAVE MERGE OF fontChar & fontFlag SECTIONS OF lcdString, EXCLUDING THE '|' MARKER.
  // (e.g., "LR DoobyoD |LL BbbblbB " --> "LLRL  DBobobbbylobDB  "). This processes only the top row 
  // (i.e., row 0) of double- or multi-row lcdStrings (e.g., "Test|B   CASE|BBBB" --> "TBe s t ", which
  // displays as bold "T" followed by plain text "est"). The setupRow123 function allows LCDfontManager
  // to process successive rows of a multi-row lcdString (defined as having more than one '|' font marker)
  // as pseudo-zero-rows. See the font-encoding test cases for examples of how this is done.
  if (fontEncoded == true) {
    merged_lcdString = "";
    for (uint8_t i = 0; i < marker_idx; i++) {
      merged_lcdString += lcdString[i]; 
      merged_lcdString += lcdString[marker_idx + 1 + i];
    } 
  } else { // fontEncoded == false, i.e., lcdString contains plain text
    merged_lcdString = "";
    for (uint8_t i = 0; i < lcdString.length(); i++) {
      merged_lcdString += lcdString[i];
      merged_lcdString += " ";
    }
    fontEncoded = true;
  }
 
  // ==[Step 3]==================== 
  // CLEAN UP THE CC_id_table, REMOVING ANY TABLE ENTRIES THAT WILL BE OVERWRITTEN BY CCs IN THE CURRENT
  // lcdString, AND DON'T EXIST ELSEWHERE IN screenImage... 
  uint8_t merged_startPos = startPos << 1; // even
  uint8_t scrn_ptr = merged_startPos;
  while (scrn_ptr < (merged_startPos + merged_lcdString.length())) {
    uint8_t fontByte = screenImage[scrn_ptr];
    // Overwrite the character before checking if it exists elsewhere in screenImage:
    screenImage.setCharAt(scrn_ptr, 0x20); // (david_2018 patch 9/26/2024) 
    if ((fontByte >= 0x08) && (fontByte <= 0x0f) && (screenImage.indexOf(fontByte) == -1)) CC_id_table[fontByte - 8] = ""; 
    scrn_ptr += 2; // even
  }
  // MERGE lcdString INTO screenImage STARTING AT screenImage[startPos]:
  screenImage.reserve(screenLength);
  screenImage = screenImage.substring(0, merged_startPos) + merged_lcdString + screenImage.substring(merged_startPos + merged_lcdString.length());

  // ==[Step 4]==================== 
  // %%%%% INITIALIZE THE MAIN LOOP:
  merged_startPos = startPos << 1; // even
  scrn_ptr = merged_startPos; 
  uint8_t myChar_ptr = scrn_ptr; // even
  uint8_t myFlag_ptr = scrn_ptr + 1; // odd
  String current_CC_Char = String(screenImage[myChar_ptr]);
  String current_CC_Flag = String(screenImage[myFlag_ptr]);
  String current_CC_id = current_CC_Char + current_CC_Flag;
  char fontChar = current_CC_Char.c_str()[0];
  char fontFlag = current_CC_Flag.c_str()[0];
  //
  // MAIN LOOP:
  // Summary: The main Font-Pal processing loop parses screenImage for unprocessed
  // custom characters (CC). It uses the CC_id String (CC_id = fontChar + fontFlag)
  // to look up the associated CC bitmap, which it loads into the HD44780 LCD chip's
  // CGRAM. In each case, it replaces the CC_id's fontChar part with a byte between
  // 0x08 and 0x0f, and the fontFlag part with " ". Font errors are flagged by
  // replacing matching CC_ids with "@ ". Each unique CC_id is stored in the eight-
  // location CC_id_table (unless stored already) at address 0-7 (given by subtrac-
  // ting eight from the 0x08-0x0f CC byte). There are two types of CC: Those that
  // are in the CC_id_table --Type (A)--, and those that are not --Type (B)--). 
  // Instances of CGRAM overflow (caused by attempts to display more than eight
  //  unique CCs) are flagged by replacing the current CC_id with "# ". 
  //
  // Note: Using an offset of 8 for the fontChar part of the CC_id avoids problems
  // caused by ASCII null characters (0x00), related to using \0 as an end-of-string
  // marker in C-strings in C and C++. This works because the HD44780's 0-8 CGRAM
  // addresses also have a set of shadow addresses 0x08-0x0f.
  //
  // The main loop checks each CC in turn. If the current_CC_id has a non-blank
  // fontFlag, we assume it must be an unprocessed CC...
  while (scrn_ptr < screenLength) {
    if (fontFlag != 0x20) {
      gBitmap = getBitmap(fontChar, fontFlag);
      if (gBitmap != nullptr) {

        // Type (A) CC --- Those that are already in the CC_id_table and have a bitmap in CGRAM: 
        // For these we replace all instances of it in screenImage with a byte (0x08-0x0f) + " "
        // that indexes the current_CC_id in the CC_id_table...
        in_CC_id_table = false; // Initial assumption: current_CC_id is not aleady in the CC_id_table
        for (CGRAM_ptr = 0; CGRAM_ptr < 8; CGRAM_ptr++)
        if (CC_id_table[CGRAM_ptr] == current_CC_id) {  // E.g., if "ql" is in CC_id_table[0-7] then...
          in_CC_id_table = true; // ...set in_CC_id_table to true, and replace all instances of
          // current_CC_id in screenImage that occur on an even byte boundary, using a custom version
          // of .replace that operates on even byte boundaries only: 
          screenImage = replaceMatchingEvenCCids(screenImage, current_CC_id, String(char(CGRAM_ptr + 8)) + String(" ")); 
        } 
             
        // Type (B) CC --- Those that are not in the CC_id-table (and therefore have no bitmap in CGRAM): 
        // If the current_CC_id is not already in the CC_id_table, save it to a free location in the table,
        // and then replace all instances of it in screenImage with the index of the current_CC_id in the
        // CC_id_table (0x08-0x0f + " " ):   
        if (in_CC_id_table == false) { 
          // Locate 1st free location in CC_id_table...  
          CGRAM_ptr = 0; while ((CGRAM_ptr < 8) && (CC_id_table[CGRAM_ptr] != "")) CGRAM_ptr++; 
          // ...and when found,
          // i) save the current_CC_id at that CC_id_table location,
          // ii) load the bitmap into CGRAM, and
          // iii) Replace all instances in screenImage with (CGRAM_ptr + 8) + " ":
          if (CGRAM_ptr < 8) {
            CC_id_table[CGRAM_ptr] = current_CC_id;  // E.g., "ql"
            lcd.createChar((CGRAM_ptr + 8), gBitmap); // Load bitmap into the HD44780 LCD chip's CGRAM
            in_CC_id_table = true; // Change in_CC_id_table to true, and then replace all instances of
            //                        current_CC_id in screenImage that occur on an even byte boundary: 
            screenImage = replaceMatchingEvenCCids(screenImage, current_CC_id, String(char(CGRAM_ptr + 8)) + String(" ")); // even only
          }
          // However, if the CC_id_table is full (due to all eight CCGRAM locations being in use), we
          // signal CGRAM overflow by replacing all instances of the current_CC_id in screenImage with "# ": 
          if (CGRAM_ptr == 8) screenImage.replace(current_CC_id, String("# ")); 
        } 
        screenImage = replaceMatchingEvenCCids(screenImage, current_CC_id, String(char(CGRAM_ptr + 8)) + String(" ")); // even only
      } 
      else screenImage = replaceMatchingEvenCCids(screenImage, current_CC_id, String("@ "));  // Signal all even instances of gBitmap == nullptr (i.e., bad fontFlag/fontChar)
    } // Or, if the current character is plain text, do nothing.
           
    // Update loop params to prepare for processing the next character:
    scrn_ptr += 2; // to remain even
    myChar_ptr = scrn_ptr; // even
    myFlag_ptr = scrn_ptr + 1; // odd
    current_CC_Char = String(screenImage[myChar_ptr]);
    current_CC_Flag = String(screenImage[myFlag_ptr]);
    current_CC_id = current_CC_Char + current_CC_Flag;
    fontChar = current_CC_Char.c_str()[0]; 
    fontFlag = current_CC_Flag.c_str()[0];
  } // END OF MAIN LOOP

    // %%%%% CC_ids ignored by the above font processing include the following:
    //       a) Plain-text characters in font-formatted Strings,
    //          e.g., "Bold|B   "; --> "BBo l d "; where the old is plain text.
    //       b) Characters in plain-text Strings e.g., "Plain Text!";
    //       c) Processed CCs, e.g. String(char(0x0a) + String(" "); 
    //       d) The "@ " (bad char/font), and "# " (CGRAM overflow) error flags.
    
  // ==[Step 5]==================== 
  // FINALLY, PRINT ALL EVEN CHARACTERS IN screenImage 0,2,4,6,..., TO THE LCD:
  String final_screenImage = "";
  for (scrn_ptr = 0; scrn_ptr < screenImage.length(); scrn_ptr += 2) final_screenImage += screenImage.charAt(scrn_ptr); // even only
  #ifdef LCD_SIZE_16x2
    lcd.setCursor(0,0); // row 0
    lcd.print(final_screenImage.substring(0, 16));
    lcd.setCursor(0,1); // row 1
    lcd.print(final_screenImage.substring(16, 32));
  #elif defined(LCD_SIZE_20x2)
    lcd.setCursor(0,0); // row 0
    lcd.print(final_screenImage.substring(0, 20));
    lcd.setCursor(0,1); // row 1
    lcd.print(final_screenImage.substring(20, 40));
  #elif defined(LCD_SIZE_20x4)
    lcd.setCursor(0,0); // row 0
    lcd.print(final_screenImage.substring(0, 20));
    lcd.setCursor(0,1); // row 1
    lcd.print(final_screenImage.substring(20, 40));
    lcd.setCursor(0,2); // row 2
    lcd.print(final_screenImage.substring(40, 60));
    lcd.setCursor(0,3); // row 3
    lcd.print(final_screenImage.substring(60, 80));
  #endif
  final_screenImage = "";
}
