import Color

proc toUint32*(bytes: seq[byte]): uint32 =
  result = (cast[uint32](bytes[0]) shl 0) or
    (cast[uint32](bytes[1]) shl 8) or
    (cast[uint32](bytes[2]) shl 16) or
    (cast[uint32](bytes[3]) shl 24)

proc toInt32*(bytes: seq[byte]): int32 =
  result = cast[int32](toUint32(bytes))

proc toUint16*(bytes: seq[byte]): uint16 =
  result = (cast[uint16](bytes[0]) shl 0) or
           (cast[uint16](bytes[1]) shl 8)

proc bgraToColor*(bytes: seq[byte]): Color =
  result.r = bytes[2]
  result.g = bytes[1]
  result.b = bytes[0]
  result.a = bytes[3]
