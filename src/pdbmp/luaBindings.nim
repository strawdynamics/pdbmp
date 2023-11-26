import playdate/api

# TODO: Making a nice interface will require the ability to pass more complex types back and forth between Lua and Nim, see comment stubs in https://github.com/samdze/playdate-nim/blob/main/src/playdate/lua.nim
proc initPdBmpLua*(): void =
  playdate.system.logToConsole("initPdBmpLua!!!")
