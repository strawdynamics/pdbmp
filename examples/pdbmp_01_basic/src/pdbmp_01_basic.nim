import playdate/api

import ../../../src/pdbmp

import bayerPatterns

var img: LCDBitmap

proc handleInit(): void =
  var aBmp = PdBmp(filePath: "bmp/aseprite/indexed-4bpp-grayscale-24-24.bmp")

  try:
    aBmp.parse()

    playdate.system.logToConsole("wh" & $(aBmp.dibHeader.imageWidth) & "," &
        $(aBmp.dibHeader.imageHeight))

    let bmpWidth = aBmp.dibHeader.imageWidth
    let bmpHeight = aBmp.dibHeader.imageHeight

    img = playdate.graphics.newBitmap(
      bmpWidth * 2,
      bmpHeight * 2,
      LCDSolidColor.kColorClear
    )

    playdate.graphics.pushContext(img)
    for x in 0..<bmpWidth:
      for y in 0..<bmpHeight:
        let sampledColor = aBmp.sample(uint32(x), uint32(y))
        let luma = float64(sampledColor.r) * 0.2126 + float64(sampledColor.g) *
            0.7152 + float64(sampledColor.b) * 0.0722

        playdate.graphics.fillRect(
          x * 2,
          y * 2,
          2,
          2,
          # if sampledColor.r == 255: bayerPatterns[0] else: bayerPatterns[30]
          bayerPatterns[int(luma) div 4]
        )

    # playdate.graphics.fillRect(0, 0, 12, 12, bayerPatterns[24])
    # playdate.graphics.fillRect(0, 0, 2, 2, makeLCDOpaquePattern(0xAA, 0xAA,
      # 0x55, 0x55, 0xAA, 0xAA, 0x55, 0x55))
    playdate.graphics.popContext()


    # for i in 0..8:
    #   playdate.system.logToConsole("p" & $(i) & " rgba: " & $(aBmp.colorPalette[
    #       i].r) & "," & $(aBmp.colorPalette[i].g) & "," & $(aBmp.colorPalette[
    #           i].b) &
    #       "," & $(aBmp.colorPalette[i].a))

    # for i in 0..18:
    #   playdate.system.logToConsole($(i) & ",0: " & $(aBmp.sample(uint32(i), 0)))
  except Exception as e:
    playdate.system.logToConsole("Error parsing BMP: " & e.msg)

proc update(): int {.raises: [].} =
  # discard 2 + 2
  img.draw(40, 40, LCDBitmapFlip.kBitmapUnflipped)

proc handler(event: PDSystemEvent, keycode: uint) {.raises: [].} =
  if event == kEventInit:
    handleInit()
    playdate.system.setUpdateCallback(update)

  # TODO:
  # if event == kEventInitLua:
  #   initPdBmpLua()

initSDK()
