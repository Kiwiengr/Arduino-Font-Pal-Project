/*---------------------------------------------------------------------------------*/
/* myFontsPrinter() - PRINT ALL FONT-PAL FONT TABLES (USE FOR DEBUG PURPOSES ONLY) */
/*---------------------------------------------------------------------------------*/
void myFontsPrinter() {  
  Serial.begin(9600);
  Serial.println("----- ARDUINO FONT-PAL CC BITMAPS -----");
  for (const CustomFont &font : fonts) {  // Use a foreach statement for a compact printout of the structs.
    Serial.print("\nFont Flag: ");
    Serial.print(font.fontFlag);
    Serial.print("\nFont Characters: ");
    Serial.print(font.fontChars);
    Serial.println("\nFont Bitmaps for Each Custom Character:");
    for (uint8_t i = 0; i < font.fontChars.length(); i++) {
      Serial.print("Character '");
      Serial.print(font.fontChars[i]);
      Serial.print("' : ");
      for (int j = 0; j < 8; j++) {
        Serial.print("0x");
        if (font.fontBits[i][j] < 0x10) Serial.print("0");
        Serial.print(font.fontBits[i][j], HEX);
        Serial.print(" ");
      }
      Serial.println();
    }
    Serial.println();
  }
  return;
}
