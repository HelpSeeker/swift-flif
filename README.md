***

## Archived!

FLIF is dead and so is this project. While both can still be used, there is only little reason to do so.

People who are interested in next gen image compression should follow the progress on the [JPEG XL reference implementation](https://gitlab.com/wg1/jpeg-xl) instead.

***

# swift-flif
swift-flif is a [FLIF](https://flif.info/) optimization script with a focus on speed. It was inspired by [flifcrush](https://github.com/matthiaskrgr/flifcrush).

### Why use swift-flif?

swift-flif's goal is to strike a balance between compression efficiency and speed. It only loops through a few of the most interesting settings instead of thousands of possible combination.  
Two examples to illustrate the efficiency of swift-flif (both images were taken from flifcrush's sample directory): 

Description | File size (in bytes) | File size (compared to the original) | File size (compared to the default settings) | Executed FLIF encoder commands | Elapsed time**
------------ | ------------- | ------------- | ------------- | ------------- | -------------
[FreedroidRPG.png](https://raw.githubusercontent.com/matthiaskrgr/flifcrush/master/samples/FreedroidRPG.png) | 38,390 | 100.00% | 151.96% | 0 | -
optimized.png* | 37,154 | 96.78% | 147.06% | 0 | 00:00:01
default.flif | 25,264 | 65.81% | 100.00% | 1 | less than a second
swift-flif.flif | 24,370 | 63.48% | 96.46% | 16 | 00:00:01
flifcrush.flif | 23,858 | 62.15% | 94.43% | 7921 | 00:11:40

Description | File size (in bytes) | File size (compared to the original) | File size (compared to the default settings) | Executed FLIF encoder commands | Elapsed time**
------------ | ------------- | ------------- | ------------- | ------------- | -------------
[screenshot.png](https://raw.githubusercontent.com/matthiaskrgr/flifcrush/master/samples/screenshot.png) | 386,223 | 100.00% | 545.74% | 0 | -
optimized.png* | 31,191 | 8.08% | 44.07% | 0 | 00:00:22
default.flif | 70,770 | 18.32% | 100.00% | 1 | 00:00:02
swift-flif.flif | 64,513 | 16.70% | 91.16% | 16 | 00:00:17
flifcrush.flif | 60,370 | 15.63% | 85.30% | 8681 | 07:07:53


*I also included the results of the optimized PNGs, because I think it's important to show that FLIF isn't always the best solution. There are still times when it's less efficient.

The optimization was done via [ECT](https://github.com/fhanau/Efficient-Compression-Tool).  
````
ect -9 <input file>
````
**All tests were done with a Ryzen 7 2700x @ 3.8 GHz

### Requirements

* [FLIF](https://github.com/FLIF-hub/FLIF)
* Bash >=4.0

### Installation

Here's how you make this script an easily available command line tool. First make the script executable via 
````
chmod +x swift-flif.sh
````
Then open .bashrc and add the script as an alias
````
alias swift-flif="path/to/the/script/swift-flif.sh"
````
### Usage
````
swift-flif [OPTIONS]... INPUT [INPUT]...
````

Option | Description
------------ | -------------
`-h, --help` | Show a help text.  
`-v, --verbose` | Print verbose information about each conversion.   
`-q, --quiet` | Suppress all non-error messages.  
`-I, --interlace` | Force swift-flif to output interlaced FLIF. This will halve the amount of executed FLIF encoder commands.  
`-N, --no-interlace` | For swift-flif to output non-interlaced FLIF. This will halve the amount of executed FLIF encoder commands.  

List of supported formats:  
````
PNG, PAM, PNM, PPM, PGM, PBM
````

### How swift-flif handles input files

swift-flif assumes that images with the same name depict the same footage.  

It differentiates between the source file (e.g. test.png) and the FLIF equivalent (e.g. test.flif).  
Based on this assumption there are 3 possible situations that swift-flif can encounter.

1. There's one source file present (no FLIF equivalent)
2. Both source file and FLIF equivalent are present  
3. There's only a FLIF file present (no source file)

swift-flif will always try to find the FLIF equivalent of a source file and vice versa. It will skip all FLIF files as input, if the source file was specified as input as well or is merely present in the same directory as the source file. At the same time it keeps track of any FLIF equivalents and prevents overwriting, if swift-flif isn't able to lower the file size further.

### FLIF transcoding

You might notice that swift-flif doesn't transcode FLIFs directly. Instead it decodes them to PNG and reencodes them as FLIF. This additional step is necessary as FLIF transcoding seems to be broken (or at least produces really weird results).  

FLIF -> FLIF will produce significantly larger files than FLIF -> PNG -> FLIF.

### Other helpful tools

The FLIF encoder has certain shortcomings when it comes to supported input file formats.  
Many popular image types aren't supported (e.g. JPG, GIF, BMP, TIFF, ...) and some PNGs might cause trouble as well (see: [libpng warning: iCCP: known incorrect sRGB profile](https://stackoverflow.com/questions/22745076/libpng-warning-iccp-known-incorrect-srgb-profile)).

For these scenarios I'd advise using [ImageMagick](https://www.imagemagick.org/script/index.php) or [GraphicsMagick](http://www.graphicsmagick.org/). They allow you to easily batch convert unsupported image formats or fix problematic PNGs.

### Things I don't plan on including

* Lossy encoding  
* Usage of ImageMagick/GraphicsMagick to support more image formats
