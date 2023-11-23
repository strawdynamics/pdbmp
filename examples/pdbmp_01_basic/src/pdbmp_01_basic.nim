import playdate/api

import ../../../src/pdbmp

import ditherPatterns

var img: LCDBitmap

proc handleInit(): void =
  # var aBmp = PdBmp(filePath: "bmp/aseprite/indexed-4bpp-grayscale-24-24.bmp")
  # var aBmp = PdBmp(filePath: "bmp/aseprite/indexed-4bpp-200-120.bmp")
  # var aBmp = PdBmp(filePath: "bmp/aseprite/indexed-8bpp-400-240.bmp")
  # var aBmp = PdBmp(filePath: "bmp/aseprite/indexed-8bpp-gb-shop.bmp")
  # var aBmp = PdBmp(filePath: "bmp/aseprite/indexed-8bpp-gb-avatars.bmp")
  # var aBmp = PdBmp(filePath: "bmp/aseprite/indexed-8bpp-gb-outdoor.bmp")
  # var aBmp = PdBmp(filePath: "bmp/aseprite/indexed-8bpp-gb-overworld.bmp")
  # var aBmp = PdBmp(filePath: "bmp/aseprite/indexed-8bpp-gb-playground.bmp")
  # var aBmp = PdBmp(filePath: "bmp/aseprite/indexed-8bpp-gb-industrial.bmp")
  # var aBmp = PdBmp(filePath: "bmp/aseprite/rgb-sprout-lands.bmp")

  # var aBmp = PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal1.bmp")
  # var aBmp = PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal1bg.bmp")
  # var aBmp = PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal1wb.bmp")
  # var aBmp = PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal4.bmp")
  # var aBmp = PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal4gs.bmp")
  # var aBmp = PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8-0.bmp")
  # var aBmp = PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8.bmp")
  # var aBmp = PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8gs.bmp")
  # var aBmp = PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8nonsquare.bmp")
  # var aBmp = PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8topdown.bmp")
  # var aBmp = PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8w124.bmp")
  # var aBmp = PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8w125.bmp")
  # var aBmp = PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8w126.bmp")
  # var aBmp = PdBmp(filePath: "bmp/bmpsuite-2.7/g/rgb32bfdef.bmp")
  var aBmp = PdBmp(filePath: "bmp/custom/rgb32bfdef2.bmp")

  try:
    aBmp.parse()

    playdate.system.logToConsole("wh" & $(aBmp.dibHeader.imageWidth) & "," &
        $(aBmp.dibHeader.imageHeight))

    let bmpWidth = aBmp.dibHeader.imageWidth
    let bmpHeight = aBmp.dibHeader.imageHeight

    img = playdate.graphics.newBitmap(
      # bmpWidth, bmpHeight,
      bmpWidth * 2, bmpHeight * 2,
      # bmpWidth * 4, bmpHeight * 4,
      LCDSolidColor.kColorClear
    )

    playdate.graphics.pushContext(img)
    for x in 0..<bmpWidth:
      for y in 0..<bmpHeight:
        let sampledColor = aBmp.sample(uint32(x), uint32(y))
        let luma = float64(sampledColor.r) * 0.2126 + float64(sampledColor.g) *
            0.7152 + float64(sampledColor.b) * 0.0722

        playdate.system.logToConsole("x,y;r,g,b,a: " & $(x) & "," & $(y) & ";" &
            $(sampledColor.r) & "," & $(sampledColor.g) & "," & $(
                sampledColor.b) & "," & $(sampledColor.a))

        playdate.graphics.fillRect(
          # x, y, 1, 1,
          x * 2, y * 2, 2, 2,
          # x * 4, y * 4, 4, 4,
          bayerPatterns8x8[int(luma) div 4],
          # asepriteDither2x2[int(luma) div 64],
        )
    playdate.graphics.popContext()
  except Exception as e:
    playdate.system.logToConsole("Error parsing BMP: " & e.msg)

proc update(): int {.raises: [].} =
  playdate.graphics.clear(LCDSolidColor.kColorWhite)
  if img != nil:
    img.draw(0, 0, LCDBitmapFlip.kBitmapUnflipped)

  return 1

proc handler(event: PDSystemEvent, keycode: uint) {.raises: [].} =
  if event == kEventInit:
    handleInit()
    playdate.system.setUpdateCallback(update)

  # TODO:
  # if event == kEventInitLua:
  #   initPdBmpLua()

initSDK()
