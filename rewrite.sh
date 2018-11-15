#!/bin/bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Settings
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

file_list=()
supported=("flif" "png" "pnm" "ppm" "pgm" "pbm" "pam")
effort_settings=(0 5 10 20 30 60 80 100)
interlace_settings=("I" "N")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Functions
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

usage() {
	echo -e "swift-flif is a flif optimization script with a focus on speed.\n"
	echo -e "Usage: swift-flif [OPTIONS]... INPUT [INPUT]...\n"
	echo -e "Options:"  
	echo -e " -h, --help\t\tshow this help"
	echo ""
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

add_file() {
	for ext in ${supported[@]}
	do
		file_ext=${1##*.}
		if [[ ${file_ext,,} = $ext ]]; then
			file_list+=("$1")
			return
		fi 
	done
	echo "'$1' isn't a supported file type!"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

decider() {
	if (( size == -1 )); then
		mv -i "temp.flif" "${input%.*}.flif"
		size=$temp_size
	elif (( temp_size < size )); then
		mv -f "temp.flif" "${input%.*}.flif"
		size=$temp_size
	else
		rm "temp.flif"
	fi
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

loop_settings() {
	for interlace in ${interlace_settings[@]}
	do
		for effort in ${effort_settings[@]}
		do
			flif -$interlace -E$effort "$input" "temp.flif"
			temp_size=$(stat -c %s "temp.flif")
			echo -e "flif -$interlace -E$effort\t| Current try: $temp_size Bytes\t| Min. size: $size Bytes"
			
			decider
		done
	done
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

results() {
		echo "##########"
		echo -e "Original ${input##*.}:\t\t$original_size Bytes"
	if (( original_flif != -1 )); then
		echo -e "Original flif:\t\t$original_flif Bytes"
	fi
		echo -e "swift-flif:\t\t$size Bytes"
		echo -e "Difference (${input##*.}):\t$(( size - original_size )) Bytes | $(bc <<< "scale=2; 100*($size-$original_size)/$original_size")%"
	if (( original_flif != -1 )); then	
		echo -e "Difference (flif):\t$(( size - original_flif )) Bytes | $(bc <<< "scale=2; 100*($size-$original_flif)/$original_flif")%"	
	fi
		echo "##########"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Main script
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

while [[ "$1" ]]
do
	case "$1" in
	-h | --help) usage; exit;;
	-*) echo -e "Unknown flag '$1' used!\n"; usage; exit;;
	*) add_file "$1"; shift;;
	esac
done

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

for input in "${file_list[@]}"
do
	if [[ ${input##*.} == flif ]]; then
		original_size=$(stat -c %s "$input")
		size=$original_size
		original_flif=-1
	elif [[ -e "${input%.*}.flif" ]]; then
		size=$(stat -c %s "${input%.*}.flif")
		original_size=$(stat -c %s "$input")
		original_flif=$size
	else
		size=-1
		original_flif=-1
	fi

	echo "##########"
	echo "Current file: $input"
	echo "##########"
	loop_settings
	results
done
