#!/bin/bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Settings
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# default extension = all files
ext="*"
# currently supported input formats according to 'man flif'
allowed=("*" "png" "pnm" "ppm" "pgm" "pbm" "pam")
# most interesting effort settings according to 'man flif'
settings=(0 5 10 20 30 60 80 100)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Functions
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Show help text
usage() {
	echo -e "\nswift-flif is a flif optimization script with a focus on speed."
	echo "Usage: $0 [-h] [-e <extension>] [ input01 [ input02 input03 ... ] ]"
	echo -e "\nThere are 3 ways to select input files:\n"
	echo "1. All files"
	echo -e "\t$ swift-flif"
	echo -e "\tConverts all supported files in the current directory."
	echo "2. All files of a certain image type"
	echo -e "\t$ swift-flif -e <extension>"
	echo -e "\tConverts all files of a certain image type in the current directory."
	echo "3. Specified files"
	echo -e "\t$ swift-flif input01 [ input02 input03 ... ]"
	echo -e "\tConverts all specified files."
	echo -e "\nAll methods automatically skip files that aren't supported by the flif encoder."
	echo "List of supported formats (according to 'man flif'):"
	echo -e "\tPNG, PAM, PNM, PPM, PGM, PBM"
	echo -e "\nThis script doesn't support flif transcoding to avoid overwriting files.\n"
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
		echo "${1##*.} isn't supported by the flif encoder! Skipping $1..."
		echo "~~~~~~~~~~~~~~~~~~"
		return
	fi

	original_size=$(stat -c %s "$1")
	
	echo "Currently working on $1"
	echo "~~~~~~~~~~~~~~~~~~"
	
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
				echo -e "flif -I -E0\t| File size: $file_size bytes"
			else	
				flif -$interlace -E$preset "$1" "temp.flif"
				temp_size=$(stat -c %s "temp.flif")
				echo -e "flif -$interlace -E${preset}\t| File size: $temp_size bytes"
			
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
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Main script
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

while getopts ":he:" ARG; do
	case "$ARG" in
	h) usage && exit;;
	e) ext="$OPTARG";;
	*) echo "Unknown flag used. Use $0 -h to show all available options." && exit;;
	esac;
done

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Check if user set image type is supported
check_support "$ext"
if [[ $unsupported = true ]]; then
	echo "$ext isn't supported by the flif encoder! Aborting..."
	echo "~~~~~~~~~~~~~~~~~~"
	exit
fi

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

echo "~~~~~~~~~~~~~~~~~~"

# Use script on all files in a directory if 
# a) no input argument is specified
# b) the first input argument is the extension flag
if [[ -z "$1" || $1 = -e* ]]; then
	for input in *.$ext
	do
		# Check if any input files exist
		if [[ -e "$input" ]]; then
			convert "$input"
		else
			echo "No input files found! Aborting..."
			echo "~~~~~~~~~~~~~~~~~~"
			exit
		fi
	done
# Use script on specified files
else
	for input in "$@"
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
