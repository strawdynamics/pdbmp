# pdbmp

```
nimble develop

nimble simulate

nimble all && open playdate.pdx
```

* https://en.wikipedia.org/wiki/BMP_file_format
* https://www.loc.gov/preservation/digital/formats/fdd/fdd000189.shtml
	* See "Microsoft page links to specific header types"
* http://fileformats.archiveteam.org/wiki/BMP
	* Symbol definitions section is useful
* BMP compression: https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-wmf/4e588f70-bd92-4a6f-b77f-35d0feaf7a57
* Demo assets
	* [GB Studio 7-11 Tileset](https://reakain.itch.io/gb-studio-7-11-tileset)
	* [GB Studio Character pack](https://the-pixel-nook.itch.io/gb-studio-character-pack)
	* [GameBoy Assets and Sprites](https://materialfuture.itch.io/gameboy-assets)
	* [GB studio overworld tiles +](https://the-pixel-nook.itch.io/gb-studio-overworld-tiles-plus)

## Notes/Limitations

* Only supports BMP files with BITMAPINFOHEADER or BITMAPV3INFOHEADER.
* Compression:
	* No true "compression" support, but support for BI_BITFIELDS + BITMAPV3INFOHEADER. This is called "compression", but is actually just pairs of RGBA bytes.
		* Not _actually_ RGBA though, the specific order is defined by the BI_BITFIELDS/BI_ALPHABITFIELDS
	* Only BI_BITFIELDS `3` (BITMAPV3INFOHEADER) or none
* Ignores concept of "important" colors.

## Notes for me

* Wiki: "In most cases, each entry in the color table occupies 4 bytes, in the order blue, green, red, 0x00"

## API sketching

* PdBmp
	* init with string path
	* sample(x, y)
	* sampleIndex(x, y)
	* getBitDepth()
	* getMaxVal() # errors if > 8bpp
	* getWidth()
	* getHeight()
