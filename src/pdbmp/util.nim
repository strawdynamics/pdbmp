import playdate/api

proc log*(str: string) =
  playdate.system.logToConsole("[pdbmp] " & str)
