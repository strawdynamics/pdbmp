import playdate/api

import ../../../src/pdbmp

import ditherPatterns

var img: LCDBitmap

let bmps = @[
  PdBmp(filePath: "bmp/aseprite/indexed-4bpp-grayscale-24-24.bmp"),
  PdBmp(filePath: "bmp/aseprite/indexed-4bpp-200-120.bmp"),
  PdBmp(filePath: "bmp/aseprite/indexed-8bpp-400-240.bmp"),
  PdBmp(filePath: "bmp/aseprite/indexed-8bpp-gb-shop.bmp"),
  PdBmp(filePath: "bmp/aseprite/indexed-8bpp-gb-avatars.bmp"),
  PdBmp(filePath: "bmp/aseprite/indexed-8bpp-gb-outdoor.bmp"),
  PdBmp(filePath: "bmp/aseprite/indexed-8bpp-gb-overworld.bmp"),
  PdBmp(filePath: "bmp/aseprite/indexed-8bpp-gb-playground.bmp"),
  PdBmp(filePath: "bmp/aseprite/indexed-8bpp-gb-industrial.bmp"),
  PdBmp(filePath: "bmp/aseprite/indexed-8bpp-normal.bmp"),
  PdBmp(filePath: "bmp/aseprite/indexed-8bpp-sprout-lands.bmp"),
  PdBmp(filePath: "bmp/aseprite/rgb-32bpp-actor2rmmz.bmp"),

  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal1.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal1bg.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal1wb.bmp"),

  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal4.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal4gs.bmp"),

  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8-0.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8gs.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8nonsquare.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8os2.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8topdown.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8w124.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8w125.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8w126.bmp"),

  PdBmp(filePath: "bmp/bmpsuite-2.7/g/rgb32.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/rgb32bfdef.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/rgb32bf.bmp"),
  PdBmp(filePath: "bmp/custom/rgb32bfdef2.bmp"),
]

var bmpIndex = 0
var bmpScale = 2

proc loadBmp(bmpIndex: int, bmpScale: int): void =
  try:
    let startMs = playdate.system.getCurrentTimeMilliseconds()
    var bmp = bmps[bmpIndex]
    bmp.load()

    let loadedAtMs = playdate.system.getCurrentTimeMilliseconds()
    playdate.system.logToConsole("Load in " & $(loadedAtMs - startMs))


    let bmpWidth = bmp.dibHeader.imageWidth
    let bmpHeight = bmp.dibHeader.imageHeight

    playdate.system.logToConsole("wh" & $(bmpWidth) & "," & $(bmpHeight))
    playdate.system.logToConsole("bpp" & $(bmp.dibHeader.bitsPerPixel))

    img = playdate.graphics.newBitmap(
      bmpWidth * bmpScale, bmpHeight * bmpScale,
      LCDSolidColor.kColorClear
    )

    let imgInitAt = playdate.system.getCurrentTimeMilliseconds()
    playdate.system.logToConsole("Img init in " & $(imgInitAt - loadedAtMs))

    playdate.graphics.pushContext(img)
    for x in 0..<bmpWidth:
      for y in 0..<bmpHeight:
        let sampledColor = bmp.sample(uint32(x), uint32(y))
        let luma = float(sampledColor.r) * 0.2126 + float(sampledColor.g) *
            0.7152 + float(sampledColor.b) * 0.0722

        # playdate.system.logToConsole("x,y;r,g,b,a: " & $(x) & "," & $(y) & ";" &
        #     $(sampledColor.r) & "," & $(sampledColor.g) & "," & $(
        #         sampledColor.b) & "," & $(sampledColor.a))

        playdate.graphics.fillRect(
          x * bmpScale, y * bmpScale, bmpScale, bmpScale,
          bayer8x8[int(luma) div 4],
          # gb4Light[int(luma) div 64],
            # gb4Dark[int(luma) div 64],
            # gb5[int(luma) div 51],
        )
    playdate.graphics.popContext()

    let imgAtMs = playdate.system.getCurrentTimeMilliseconds()
    playdate.system.logToConsole("Img rendered in " & $(imgAtMs - imgInitAt))
  except Exception as e:
    playdate.system.logToConsole("Error parsing BMP: " & e.msg)

proc handleInit(): void =
  playdate.display.setRefreshRate(50)
  loadBmp(bmpIndex, bmpScale)

proc update(): int {.raises: [].} =
  let buttonState = playdate.system.getButtonsState()
  var needsLoad = false
  let oldBmpIndex = bmpIndex

  if buttonState.pushed.contains(PDButton.kButtonLeft):
    bmpIndex -= 1
    if bmpIndex < 0:
      bmpIndex = bmps.len - 1
    needsLoad = true

  if buttonState.pushed.contains(PDButton.kButtonRight):
    bmpIndex += 1
    if bmpIndex >= bmps.len:
      bmpIndex = 0
    needsLoad = true

  if buttonState.pushed.contains(PDButton.kButtonUp):
    bmpScale += 1
    if bmpScale > 4:
      bmpScale = 4
    needsLoad = true

  if buttonState.pushed.contains(PDButton.kButtonDown):
    bmpScale -= 1
    if bmpScale < 1:
      bmpScale = 1
    needsLoad = true

  if needsLoad:
    var oldBmp = bmps[oldBmpIndex]
    oldBmp.unload()

    loadBmp(bmpIndex, bmpScale)

  playdate.graphics.clear(LCDSolidColor.kColorWhite)
  if img != nil:
    img.draw(0, 0, LCDBitmapFlip.kBitmapUnflipped)

  playdate.system.drawFPS(0, 0)

  return 1

proc handler(event: PDSystemEvent, keycode: uint) {.raises: [].} =
  if event == kEventInit:
    handleInit()
    playdate.system.setUpdateCallback(update)

  # TODO:
  # if event == kEventInitLua:
  #   initPdBmpLua()

initSDK()
