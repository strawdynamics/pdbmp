
import sequtils, strutils, os, strformat

# This file is designed to be `included` directly from a nimble file, which will make `switch` and `task`
# implicitly available. This block just fixes auto-complete in IDEs
when not compiles(task):
  import system/nimscript


proc bundlePDX2() =
  ## Bundles the pdx file
  exec(pdcPath() & " --verbose -sdkpath " & sdkPath() & " source " &
      projectName())

task all2, "Build for both the simulator and the device":
  let args = taskArgs("all2")
  var simulatorBuild = "debug"
  var deviceBuild = "release"
  # Only release device build are supported on macOS at the moment.
  if args.contains("debug") and not defined(macosx):
    deviceBuild = "debug"
  elif args.contains("release"):
    simulatorBuild = "release"
  nimble "-d:simulator", fmt"-d:{simulatorBuild}", "build", "--verbose"
  postBuild(Target.simulator)
  nimble "-d:device", fmt"-d:{deviceBuild}", "build", "--verbose"
  postBuild(Target.device)
  bundlePDX2()
