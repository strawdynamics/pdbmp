import sequtils
import std/strutils

import playdate/api

proc log*(str: string) =
  playdate.system.logToConsole("[pdbmp] " & str)

proc logSeq*(seqq: tuple) =
  var toLog: seq[string] = @[]
  for arg in seqq.fields:
    toLog.add($(arg))

  log(toLog.join(", "))
