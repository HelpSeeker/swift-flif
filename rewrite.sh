#!/bin/bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Settings
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Set default values
input_list=()
flif_list=()
verbose=false
quiet=false

# List of supported file formats
# FLIF gets handled separately 
supported=("png" "pnm" "ppm" "pgm" "pbm" "pam")
# Most interesting effort settings according to 'man flif'
effort_settings=(0 5 10 20 30 60 80 100)
# Interlace settings. Can get overwritten by user.
interlace_settings=("I" "N")



# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Functions
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Show help
usage() {
	echo -e "swift-flif is a flif optimization script with a focus on speed.\n"
	echo -e "Usage: swift-flif [OPTIONS]... INPUT [INPUT]...\n"
	echo -e "Supported formats:"
	echo -e " FLIF, PNG, PAM, PNM, PPM, PGM, PBM\n"
	echo -e "Options:"  
	echo -e " -h, --help\t\tshow this help"
	echo -e " -v, --verbose\t\tprint verbose information"
	echo -e " -q, --quiet\t\tsurpress all non-error output"
	echo -e " -I, --interlace\tforce interlaced FLIF"
	echo -e " -N, --no-interlace\\tforce non-interlaced FLIF\n"
	echo -e "For more infos visit https://github.com/HelpSeeker/swift-flif"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Show error message and exit
throw_error() {
	echo -e "### Error: $1"
	exit
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Parse input files specified by the user
add_file() {
	file_ext=${1##*.}
	
	# Add any *.flif files to flif_list
	# Skip files that are already present in the list
	if [[ ${file_ext,,} = "flif" ]]; then 
		for flif in "${flif_list[@]}"
		do
			if [[ "$1" = "$flif" ]]; then return; fi
		done
		flif_list+=("$1")
		return
	fi
	
	# Add all other input files to input_list
	# Skip files that are already present in the list
	# or unsupported by the FLIF encoder
	for ext in ${supported[@]}
	do
		if [[ ${file_ext,,} = "$ext" ]]; then
			for input in "${input_list[@]}"
			do
				if [[ "$1" = "$input" ]]; then return; fi
			done
			input_list+=("$1")
			return
		fi 
	done
	
	echo "'$1' isn't a supported file type!"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Add FLIFs to input_list
sort_lists() {
	for flif in "${flif_list[@]}"
	do
		existing_source=false
		
		# Add source file instead of FLIF if present
		# Source file == PNG, PNM, ... with the same filename
		for ext in ${supported[@]}
		do
			if [[ -e "${flif%.flif}.$ext" ]]; then
				existing_source=true
				add_file "${flif%.flif}.$ext"
			fi
		done
		
		# Skip FLIF if source file already present in input_list
		if [[ $existing_source = false ]]; then 
			input_list+=("$flif")
		fi
	done
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Get necessary input information
get_infos() {
	only_flif=false
	no_flif=false
	with_flif=false
	file_ext=${input##*.}
	
	# decide mode (used in print_results)
	# get original size(s)
	if [[ ${file_ext,,} = "flif" ]]; then
		only_flif=true
		flif -d "$input" "${input%.flif}.png"
		orig_flif="$input"
		orig_flif_size=$(stat -c %s "$orig_flif")
		input="${input%.flif}.png"
		min_size=$(stat -c %s "$orig_flif")
	elif [[ -e "${input%.*}.flif" ]]; then
		with_flif=true
		orig_flif="${input%.*}.flif"
		orig_flif_size=$(stat -c %s "$orig_flif")
		orig_input_size=$(stat -c %s "$input")
		min_size=$(stat -c %s "$orig_flif")
	else
		no_flif=true
		orig_input_size=$(stat -c %s "$input")
		min_size=-1
	fi	
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Loop through the most interesting settings
loop_settings() {
	for interlace in ${interlace_settings[@]}
	do
		for effort in ${effort_settings[@]}
		do
			flif -e -$interlace -E$effort --overwrite "$input" "temp.flif"
			current_command="flif -$interlace -E$effort"
			current_size=$(stat -c %s "temp.flif")
			
			if (( current_size < min_size || min_size == -1 )); then
				mv -f "temp.flif" "${input%.*}.flif"
				min_command="$current_command"
				min_size=$current_size
			fi
			
			if [[ $verbose = true ]]; then
				echo -e "$current_command\t| Current try: $current_size Bytes\t| Min. size: $min_size Bytes"
			fi
		done
	done
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Print results based on mode (from get_infos)
print_results() {
	echo "###"
	
	# only FLIF without any source file
	if [[ $only_flif = true ]]; then
		abs_flif_diff=$(( min_size - orig_flif_size ))
		rel_flif_diff=$(bc <<< "scale=2; 100*($min_size-$orig_flif_size)/$orig_flif_size")
		
		echo -e "Old size:\t\t$orig_flif_size Bytes"
		# Different output depending on swift-flif success (= lower file size)
		if (( orig_flif_size <= min_size )); then
			echo "Swift-flif couldn't optimize the image further!"
		else
			echo -e "New size:\t\t$min_size Bytes"
			echo -e "Savings:\t\t$abs_flif_diff Bytes (${rel_flif_diff}%)"
		fi
	# both source file and corresponding FLIF present	
	elif [[ $with_flif = true ]]; then
		abs_flif_diff=$(( min_size - orig_flif_size ))
		rel_flif_diff=$(bc <<< "scale=2; 100*($min_size-$orig_flif_size)/$orig_flif_size")
		abs_input_diff=$(( min_size - orig_input_size ))
		rel_input_diff=$(bc <<< "scale=2; 100*($min_size-$orig_input_size)/$orig_input_size")
	
		echo -e "Original ${input##*.} size:\t\t\t$orig_input_size Bytes"
		echo -e "Original flif size:\t\t\t$orig_flif_size Bytes"
		echo -e "New flif size:\t\t\t\t$min_size Bytes"
		# Different output depending on swift-flif success (= lower file size)
		# for both the source and FLIF file
		if (( abs_input_diff >= 0 )); then
			echo -e "The best attempt is $abs_input_diff Bytes (${rel_input_diff}%) larger than the original ${input##*.}!"
		else
			echo -e "Savings (compared to ${input##*.}):\t\t$abs_input_diff Bytes (${rel_input_diff}%)"
		fi
		if (( orig_flif_size <= min_size )); then
			echo "Swift-flif couldn't optimize the existing FLIF further!"
		else
			echo -e "Savings (compared to existing FLIF):\t$abs_flif_diff Bytes (${rel_flif_diff}%)"
		fi	
	# only source file; no corresponding FLIF present		
	elif [[ $no_flif = true ]]; then
		abs_input_diff=$(( min_size - orig_input_size ))
		rel_input_diff=$(bc <<< "scale=2; 100*($min_size-$orig_input_size)/$orig_input_size")
		
		echo -e "Original ${input##*.} size:\t$orig_input_size Bytes"
		echo -e "New flif size:\t\t$min_size Bytes"
		# Different output depending on swift-flif success (= lower file size)
		if (( abs_input_diff >= 0 )); then
			echo -e "The best attempt is $abs_input_diff Bytes (${rel_input_diff}%) larger than the original ${input##*.}!"
		else
			echo -e "Savings:\t\t$abs_input_diff Bytes (${rel_input_diff}%)"
		fi
	# Basically useless
	else
		throw_error "No conversion mode in print_results()."
	fi
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Main script
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Parse input flags/files
while [[ "$1" ]]
do
	case "$1" in
	-h | --help) usage; exit;;
	-v | --verbose) verbose=true; shift;;
	-q | --quiet) quiet=true; shift;;
	-I | --interlace) interlace=true; shift;;
	-N | --no-interlace) no_interlace=true; shift;;
	-*) throw_error "Unknown flag '$1' used!";;
	*) add_file "$1"; shift;;
	esac
done

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Create final input_list
sort_lists

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Check input validity

if [[ $verbose = true && $quiet = true ]]; then
	throw_error "Output can't be quiet and verbose at the same time!"
fi

# To avoid confusion
# Other solution would be to enable default behaviour in such a case
if [[ $interlace = true && $no_interlace = true ]]; then
	throw_error "-I (--interlace) and -N (--no-interlace) are mutually exclusive!"
	exit
elif [[ $interlace = true ]]; then
	interlace_settings=("I")
elif [[ $no_interlace = true ]]; then
	interlace_settings=("N")
fi

if [[ -z "${input_list[@]}" ]]; then
	throw_error "No input files specified!"
fi

# In case user has a file called temp.flif saved
# Would get deleted by the script
# Also throws error if swift-flif was interrupted by user and couldn't delete temp.flif
# but better safe than sorry
if [[ -e temp.flif ]]; then
	throw_error "temp.flif is used internally by swift-flif!\nPlease ensure there's no such file in the current dir to avoid data loss."
fi

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Loop through all files in input_list
for input in "${input_list[@]}"
do
	if [[ $verbose = true ]]; then
		echo -e "###\nCurrent file: $input\n###"
	elif [[ $quiet = false ]]; then
		echo -e "Current file: $input"
	fi
	
	get_infos
	loop_settings
	if [[ $verbose = true ]]; then print_results; fi
	
	# Delete PNG created for FLIF input (since direct transcoding is buggy)
	# This PNG wasn't present before running swift-flif
	if [[ $only_flif = true ]]; then rm "$input"; fi
	rm temp.flif 2> /dev/null
done
