import playdate/api

import ../../../src/pdbmp
import ../../../src/pdbmp/Color

import ditherPatterns
import Vector3

let bmpScale = 2

var normalBmp: PdBmp
var img: LCDBitmap
var normalMap: seq[Vector3] = @[]

var lightPos = Vector3(x: 40'f32, y: 20'f32, z: 50'f32)

# Assumes given normal is pre-normalized
proc calculateBrightness(
  surfacePoint: Vector3,
  normal: Vector3,
  lightPos: Vector3,
): float32 =
  # Direction from surface point to light source
  let lightDir = normalize(lightPos - surfacePoint)
  let sqDist = lightPos.squareDistance(surfacePoint)
  # Inverse square law for light intensity, but with some fudge
  let intensity = 300.0'f32 / (sqDist * 0.1'f32)

  # Apply intensity and clamp to non-negative values
  let brightness: float32 = max(dot(normal, lightDir) * intensity, 0.0'f32)
  return brightness.min(1)

proc handleInit(): void =
  try:
    playdate.display.setRefreshRate(50)

    normalBmp = PdBmp(filePath: "bmp/aseprite/indexed-8bpp-normal.bmp")
    normalBmp.load()
    let bmpWidth = normalBmp.dibHeader.imageWidth
    let bmpHeight = normalBmp.dibHeader.imageHeight

    img = playdate.graphics.newBitmap(
      bmpWidth * bmpScale, bmpHeight * bmpScale,
      LCDSolidColor.kColorClear
    )

    for y in 0..<bmpHeight:
      for x in 0..<bmpWidth:
        let sampledColor = normalBmp.sample(uint32(x), uint32(y))
        let normalVec = vector3FromNormal(
          sampledColor.r,
          sampledColor.g,
          sampledColor.b
        ).normalize
        normalMap.add(normalVec)

    normalBmp.unload()
  except Exception as e:
    playdate.system.logToConsole("Error parsing BMP: " & e.msg)
    return


proc update(): int {.raises: [].} =
  playdate.graphics.clear(LCDSolidColor.kColorWhite)

  let buttonState = playdate.system.getButtonsState()

  if buttonState.current.contains(PDButton.kButtonLeft):
    lightPos.x -= 1
  if buttonState.current.contains(PDButton.kButtonRight):
    lightPos.x += 1
  if buttonState.current.contains(PDButton.kButtonUp):
    lightPos.y -= 1
  if buttonState.current.contains(PDButton.kButtonDown):
    lightPos.y += 1

  let baseLuma = 255'f32

  try:
    if img != nil:
      let bmpWidth = normalBmp.dibHeader.imageWidth
      let bmpHeight = normalBmp.dibHeader.imageHeight
      playdate.graphics.pushContext(img)
      for y in 0..<bmpHeight:
        for x in 0..<bmpWidth:
          let normalVec = normalMap[x * bmpHeight + y]
          let surfacePoint = Vector3(x: float32(x), y: float32(y), z: 0'f32)

          let brightness = calculateBrightness(surfacePoint, normalVec, lightPos)

          playdate.graphics.fillRect(
            x * bmpScale, y * bmpScale, bmpScale, bmpScale,
            bayer8x8[int(baseLuma * brightness) div 4],
            # gb4Light[int(luma) div 64],
              # gb4Dark[int(luma) div 64],
              # gb5[int(luma) div 51],
          )
      playdate.graphics.popContext()
  except Exception as e:
    playdate.system.logToConsole("Error sampling: " & e.msg)


  img.draw(0, 0, LCDBitmapFlip.kBitmapUnflipped)

  playdate.system.drawFPS(0, 0)

  return 1

proc handler(event: PDSystemEvent, keycode: uint) {.raises: [].} =
  if event == kEventInit:
    handleInit()
    playdate.system.setUpdateCallback(update)

initSDK()
