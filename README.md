# pdbmp

BMP loader for Playdate, written in Nim. Designed primarily for use with 8bpp BMP files (palletted 256 color). Also supports 1, 4, and 32bpp. 16 and 24bpp files not currently supported. This could be used for:

* Sampling grayscale textures for use in "mode 7" or similar 2.5/3D applications.
* Working in color or grayscale and applying an "auto dither" on Playdate. In particular, rendering at 2x can give you something similar in both perceived bit depth and effective resolution to the original Game Boy.
* Making tilemaps if you wanted to avoid using something like LDtk for whatever reason.
* Storing normal or other maps
* ???

## Limitations

* No good docs or easy install.
* Only supports BMP files with BITMAPCOREHEADER, BITMAPINFOHEADER or BITMAPV3INFOHEADER.
* No 16/24bpp BMP support. I highly recommend working with 8bpp or less.
* Compressed BMPs not supported.
* Ignores concept of "important" colors.

## Resources

* https://en.wikipedia.org/wiki/BMP_file_format
* https://www.loc.gov/preservation/digital/formats/fdd/fdd000189.shtml
	* See "Microsoft page links to specific header types"
* http://fileformats.archiveteam.org/wiki/BMP
	* Symbol definitions section is useful
* BMP compression: https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-wmf/4e588f70-bd92-4a6f-b77f-35d0feaf7a57

### Demo asset credits

* [GB Studio 7-11 Tileset](https://reakain.itch.io/gb-studio-7-11-tileset)
* [GB Studio Character pack](https://the-pixel-nook.itch.io/gb-studio-character-pack)
* [GameBoy Assets and Sprites](https://materialfuture.itch.io/gameboy-assets)
* [GB studio overworld tiles +](https://the-pixel-nook.itch.io/gb-studio-overworld-tiles-plus)
* [Sprout Lands](https://cupnooble.itch.io/sprout-lands-asset-pack)
* [Ocean's Nostalgia MZ Heroes](https://oceansdream.itch.io/nostalgia-mz-heroes)
* [Various Normal Map Patterns](https://opengameart.org/content/various-normal-map-patterns)

## Want to help?

### Contributing

Thanks for your interest in contributing to pdbmp! Before you get started:

1. Read and agree to follow the [code of conduct (Contributor Covenant 2.1)](./CODE_OF_CONDUCT.md).
2. This was the first thing I wrote in Nim, and I don't have a lot of experience with languages like C/C++ (or binary file parsing, for that matter). Please be gentle!
3. Before you start work, check the [open issues](https://github.com/strawdynamics/pdportal/issues) to make sure there isn't an existing issue for the fix or feature you want to work on.
4. If there's not already a relevant issue, [open a new one](https://github.com/strawdynamics/pdportal/issues/new). Your new issue should describe the fix or feature, why you think it's necessary, and how you want to approach the work (please use one of the issue templates).
5. Project maintainers will review your proposal and work with you to figure out next steps!

### Running locally

``` bash
nimble develop

nimble simulate

# Kinda sorta gets you partway toward something that could be probably used with C, if you add `exportc` throughout the code
nim c --nimcache:./.nc --header:libpdbmp.h --compileOnly --app:staticlib src/pdbmp.nim
```
