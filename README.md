# swift-flif
swift-flif is a [FLIF](https://flif.info/) optimization script with a focus on speed. It was inspired by [flifcrush](https://github.com/matthiaskrgr/flifcrush).

## Why use swift-flif?

swift-flif's goal is to strike a balance between compression efficiency and speed. It only loops through a few of the most interesting settings instead of thousands of possible combination.  
Two examples to illustrate the efficiency of swift-flif (both images were taken from flifcrush's sample directory): 

Description | File size (in bytes) | File size (compared to the original) | File size (compared to the default settings) | Executed FLIF encoder commands | Elapsed time**
------------ | ------------- | ------------- | ------------- | ------------- | -------------
FreedroidRPG.png | 38,390 | 100.00% | 151.96% | 0 | -
optimized.png* | 37,154 | 96.78% | 147.06% | 0 | 00:00:01
default.flif | 25,264 | 65.81% | 100.00% | 1 | less than a second
swift-flif.flif | 24,370 | 63.48% | 96.46% | 16 | 00:00:01
flifcrush.flif | 23,858 | 62.15% | 94.43% | 7921 | 00:11:40

Description | File size (in bytes) | File size (compared to the original) | File size (compared to the default settings) | Executed FLIF encoder commands | Elapsed time**
------------ | ------------- | ------------- | ------------- | ------------- | -------------
screenshot.png | 386,223 | 100.00% | 545.74% | 0 | -
optimized.png* | 31,191 | 8.08% | 44.07% | 0 | 00:00:22
default.flif | 70,770 | 18.32% | 100.00% | 1 | 00:00:02
swift-flif.flif | 64,513 | 16.70% | 91.16% | 16 | 00:00:17
flifcrush.flif | 60,370 | 15.63% | 85.30% | 8681 | will be added later


*I also included the results of the optimized PNGs, because I think it's important to show that FLIF isn't always the best solution. There are still times when it's less efficient.

The optimization was done via [ECT](https://github.com/fhanau/Efficient-Compression-Tool).  
`ect -9 <input file>`  

**All tests were done with a Ryzen 7 2700x @ 3.8 GHz

## Requirements

* [FLIF](https://github.com/FLIF-hub/FLIF)
* Bash >=4.0

## Installation

Here's how you make this script an easily available command line tool. First make the script executable via 

`chmod +x swift-flif.sh`

Then open .bashrc and add the script as an alias

`alias swift-flif="path/to/the/script/swift-flif.sh"`

## Usage

`Usage: swift-flif [-h] [-e <extension>] [ input01 [ input02 input03 ... ] ]`

There are 3 ways to select input files:

Command | Description
------------ | -------------
`swift-flif` | Converts all files in the current directory to FLIF  
`swift-flif -e <extension>` | Converts all files of a certain image type in the current directory to FLIF  
`swift-flif input01 [ input02 input03 ... ]` | Converts all specified files to FLIF  

All methods automatically skip files that aren't supported by the FLIF encoder.

List of supported formats (according to 'man flif'):  
`PNG, PAM, PNM, PPM, PGM, PBM`

Please note that this script doesn't support FLIF transcoding to avoid overwriting files.
