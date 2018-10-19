#!/bin/bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Settings
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Default extension = all files
ext="*"
# Currently supported input formats according to 'man flif'
allowed=("*" "png" "pnm" "ppm" "pgm" "pbm" "pam")
# Most interesting effort settings according to 'man flif'
settings=(0 5 10 20 30 60 80 100)
# Other default values
verbose=false
quiet=false
files=()


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Functions
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Show help text
usage() {
	echo -e "swift-flif is a flif optimization script with a focus on speed.\n"
	echo -e "Usage: swift-flif [OPTIONS]..."
	echo -e "  or   swift-flif [OPTIONS]... INPUT [INPUT]...\n"
	echo -e "Options:"  
	echo -e " -h, --help\t\tshow this help"
	echo -e " -v, --verbose\t\tshow verbose info"
	echo -e " -q, --quiet\t\tsurpress non-error output"
	echo -e " -e <extension>\t\tuse swift-flif only on a certain extension\n"
	echo -e "Examples on how to use swift-flif:\n"
	echo -e " $ swift-flif"
	echo -e " Converts all supported files in the current directory.\n"
	echo -e " $ swift-flif -e png -v"
	echo -e " Converts all PNGs in the current directory."
	echo -e " Shows verbose information.\n"
	echo -e " $ swift-flif -q test01.png test02.png"
	echo -e " Converts test01.png and test02.png."
	echo -e " Prints no information.\n"
	echo -e "swift-flif automatically skips unsupported file types.\n"
	echo -e "Supported formats (according to 'man flif'):"
	echo -e " PNG, PAM, PNM, PPM, PGM, PBM\n"
	echo -e "swift-flif doesn't currently support flif transcoding."
	echo -e "It will be added in the near future.\n"
	echo -e "See: https://github.com/HelpSeeker/swift-flif for more infos."
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Checks if the input string is a supported image format
check_support() {
	unsupported=true
	
	for check in "${allowed[@]}"
	do
		if [[ ${1,,} = "$check" ]]; then
			unsupported=false
			break
		fi
	done
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

convert() {
	# Check if the input file is supported by flif
	# Weeds out unwanted files when using the script on all files in a directory
	check_support "${1##*.}"
	if [[ $unsupported = true ]]; then
		if [[ $verbose = true ]];then
			if [[ ${1##*.} = "flif" ]]; then
				echo "flif transcoding is currently not supported by swift-flif! Skipping $1 ..."
			else
				echo "${1##*.} isn't supported by the flif encoder! Skipping $1 ..."
			fi
			echo "~~~~~~~~~~~~~~~~~~"
		fi
		return
	fi

	original_size=$(stat -c %s "$1")
	
	if [[ $quiet = false ]]; then echo "Currently working on $1"; fi
	if [[ $verbose = true ]]; then echo "~~~~~~~~~~~~~~~~~~"; fi
	
	# Loop through the interlacing settings
	for interlace in "I" "N"
	do
		# Loop through the effort settings
		for preset in "${settings[@]}"
		do
			if [[ $preset == 0 && $interlace = "I" ]]; then
				flif -I -E0 --overwrite "$1" "${1%.${ext}}.flif"
				file_size=$(stat -c %s "${1%.${ext}}.flif")
				best_command="flif -I -E0"
				if [[ $verbose = true ]]; then echo -e "flif -I -E0\t| File size: $file_size bytes"; fi
			else	
				flif -$interlace -E$preset "$1" "temp.flif"
				temp_size=$(stat -c %s "temp.flif")
				if [[ $verbose = true ]]; then echo -e "flif -$interlace -E${preset}\t| File size: $temp_size bytes"; fi
			
				if (( temp_size < file_size )); then
					file_size=$temp_size
					best_command="flif -$interlace -E$preset"
				
					rm "${1%.${ext}}.flif"
					mv "temp.flif" "${1%.${ext}}.flif"
				else
					rm "temp.flif"
				fi
			fi
		done
	done
	
	if [[ $verbose = true ]];then 
		# Calculate savings (or in rare cases increase in size)
		diff_abs=$(( file_size - original_size ))
		diff_per=$(bc <<< "scale=2; $diff_abs*100/$original_size")
		
		# Print general infos about the conversion
		echo "~~~~~~~~~~~~~~~~~~"
		echo "Best compression: $best_command"
		echo "Original size: $original_size"
		echo "Final flif size: $file_size"
		echo "Difference: $diff_abs (${diff_per}%)"
		echo "~~~~~~~~~~~~~~~~~~"
	fi
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Main script
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Parse flags and input files (if any)
while [[ "$1" ]]
do
	case "$1" in
	-h | --help) usage; exit;;
	-v | --verbose) verbose=true; shift;;
	-q | --quiet) quiet=true; shift;;
	-e) ext="$2"; shift 2;;
	-*) echo "Unknown flag '${1}' used!"; exit;;
	*) files+=("$1"); shift;;
	esac
done

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Check if user set image type is supported
check_support "$ext"
if [[ $ext = "flif" ]]; then
	echo "flif transcoding is currently not supported by swift-flif!"
	exit
elif [[ $unsupported = true ]]; then
	echo "$ext isn't supported by the flif encoder!"
	exit
fi

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if [[ $quiet = "true" && $verbose = "true" ]]; then
	echo "Terminal output can't be quiet and verbose at the same time!"
	exit
fi

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if [[ $verbose = true ]]; then echo "~~~~~~~~~~~~~~~~~~"; fi

# Use script on all files in a dir if the files array is empty
if [[ -z "${files[@]}" ]]; then
	for input in *.$ext
	do
		# Check if any input files exist
		if [[ -e "$input" ]]; then
			convert "$input"
		else
			echo "No input files found!"
			exit
		fi
	done
# Use script on specified files
else
	for input in "${files[@]}"
	do
		# Check if the specified files exist
		if [[ -e "$input" ]]; then
			convert "$input"
		else
			echo "$input doesn't exist! Skipping..."
			echo "~~~~~~~~~~~~~~~~~~"
		fi
	done
fi
