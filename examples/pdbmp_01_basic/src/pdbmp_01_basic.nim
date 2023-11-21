import playdate/api

import ../../../src/pdbmp

proc handleInit(): void =
  var aBmp = PdBmp(filePath: "bmp/aseprite/indexed-4bpp-24-24.bmp")
  aBmp.printFilePath()
  try:
    aBmp.parse()
    for i in 0..8:
      playdate.system.logToConsole("p" & $(i) & " rgba: " & $(aBmp.colorPalette[
          i].r) & "," & $(aBmp.colorPalette[i].g) & "," & $(aBmp.colorPalette[
              i].b) &
          "," & $(aBmp.colorPalette[i].a))
  except Exception as e:
    playdate.system.logToConsole("Error parsing BMP: " & e.msg)

proc update(): int {.raises: [].} =
  discard 2 + 2

proc handler(event: PDSystemEvent, keycode: uint) {.raises: [].} =
  if event == kEventInit:
    handleInit()
    playdate.system.setUpdateCallback(update)

  # TODO:
  # if event == kEventInitLua:
  #   initPdBmpLua()

initSDK()
