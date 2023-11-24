import math

type Vector3* = object
  x*, y*, z*: float32

proc `-`*(v1, v2: Vector3): Vector3 =
  result.x = v1.x - v2.x
  result.y = v1.y - v2.y
  result.z = v1.z - v2.z

proc normalize*(v: Vector3): Vector3 {.inline.} =
  let lenRecip = 1 / sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
  result.x = v.x * lenRecip
  result.y = v.y * lenRecip
  result.z = v.z * lenRecip

proc squareDistance*(v1, v2: Vector3): float32 {.inline.} =
  let dx = v2.x - v1.x
  let dy = v2.y - v1.y
  let dz = v2.z - v1.z
  # Faster on device than e.g. `(v2.x - v1.x) ^ 2`
  dx * dx + dy * dy + dz * dz

proc distance*(v1, v2: Vector3): float32 =
  sqrt(squareDistance(v1, v2))

proc dot*(v1, v2: Vector3): float32 {.inline.} =
  v1.x * v2.x + v1.y * v2.y + v1.z * v2.z

const Recip127_5 = 1'f32 / 127.5'f32
const Recip255 = 1'f32 / 255'f32

proc vector3FromNormal*(r, g, b: uint8): Vector3 {.inline.} =
  # Byte to -1, 1 float
  result.x = (float32(r) * Recip127_5 - 1.0'f32)
  result.y = (float32(g) * Recip127_5 - 1.0'f32)
  result.z = float32(b) * Recip255
