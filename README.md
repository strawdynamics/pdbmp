# pdbmp

```
nimble develop
```

* https://en.wikipedia.org/wiki/BMP_file_format
* https://www.loc.gov/preservation/digital/formats/fdd/fdd000189.shtml
	* See "Microsoft page links to specific header types"
* BMP compression: https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-wmf/4e588f70-bd92-4a6f-b77f-35d0feaf7a57
* Images in `bmp` folder from:
	* https://www.w3.org/People/mimasa/test/imgformat/
	* https://bmptestsuite.sourceforge.io/

## Notes/Limitations

* For paletted images, Aseprite uses the first index as "transparent". pdbmp follows this convention.
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
