#!/bin/bash

################################################################
# This program applies a simple RLE-compressing to the input
#
# Any run of 3 or more duplicate bytes becomes <len>, $dupe_byte
# A run of non-packable raw data becomes ($80 + len), <bytes>
#
# Converted to bash script from Sergey Ryazanov's C implementation:
#
# https://github.com/rsa9000/rle-util/blob/master/rle.c
#
# (with minor tweaks here and there for my project's needs)

verbose=0
if [[ "$1" == "-v" ]] ; then
	shift
	verbose=1
fi

cols=$1			# screen width input file was for, only for file-naming
in_file=$2		# input file
out_file=$3		# compressed output file
orig_file=$4		# if set, this is the non-trimmed uncompressed original .SEQ

tmpdir="/tmp/mp-trim-ws-compress-tmp"

rle_hex_file="$tmpdir/compress-$cols.hex"

mkdir -p "$tmpdir"
rm -f "$rle_hex_file" "$out_file"

echo "Compressing $in_file ..."

ch=0
len=0
flush=0
repeat=0
buf=()

IFS=
LANG=C

exec 6< "$in_file"
touch "$rle_hex_file"

function write_buffer {
	column=0
	if (( verbose )); then
		echo "[DATA] Saved incompressible block of $flush bytes."
	fi

	for (( i = 0 ; i < flush ; i++ )) ; do
		column=$((column + 1))
		echo -n "${buf[$i]} "  >> "$rle_hex_file"
		if (( column == 16 )) ; then
			column=0
			echo -e -n "\n   " >> "$rle_hex_file"
		fi
	done
}


while read -u 6 -n 1 -d '' -r bin ; do
	printf -v ch %d \'$bin  # converts the raw file byte to decimal

	if [ -n "$ch" ] ; then

		bl="${#buf[@]}"
		buf[$((bl + 1))]=$(printf "%01.2x" "$ch")
		((len++))
	fi

	m2="${buf[$(( len - 2 )) ]}"
	m1="${buf[$(( len - 1 )) ]}"

	if (( repeat )) ; then

		# There are always at least 2 bytes in buffer
		if [[ "$m2" != "$m1" ]] ; then
			flush=$(( len - 1 ))
			repeat=0
		elif (( len == "0x7f" )) || [ -z "$ch" ] ; then
			flush="$len"
			repeat=0
		fi

		if (( flush )) ; then
			if (( verbose )); then
				echo " [RUN] Declared run of $len bytes of value \$${buf[0]}."
			fi
			printf "\n%01.2x " "$(( flush + 1))" >> "$rle_hex_file"
			printf "%s"        "${buf[0]}"       >> "$rle_hex_file"

		fi
	else
		if (( len >= 2 )) && [[ "$m2" == "$m1" ]] ; then
			flush=$(( len - 2 ))
			repeat=1
		elif (( len == "0x81" )) ; then
			flush="0x80"
		elif [ -z "$ch" ] ; then
			flush="$len"
		fi

		if (( flush )) ; then
			printf "\n%01.2x " $(( flush + "0x80")) >> "$rle_hex_file"
			write_buffer
		fi
	fi

	if (( flush )) ; then
		for (( i = 0 ; i < flush ; i++ )) ; do
			unset buf[$i]
		done
		buf=("${buf[@]}")

		len=$(( len - flush ))
		flush=0
	fi
done

echo "" >> "$rle_hex_file"

exec 6<&-

# now turn the compressed data into an actual binary file.
xxd -r -p "$rle_hex_file" "$out_file"

in_len=$(wc -c < "$in_file")
out_len=$(wc -c < "$out_file")

rle_change=$(( in_len-out_len ))
ratio=$(printf "%.1f"  $(bc <<< "100 - ($out_len/$in_len)*100"))

echo "COMPRESS RLE: input file shortened by ${rle_change#-} bytes."

if [ -n "$orig_file" ] ; then
	orig_len=$(wc -c < "$orig_file")
	ratio2=$(printf "%.1f"  $(bc <<< "100 - ($out_len/$orig_len)*100"))
	echo "(files were $orig_len, $in_len, and $out_len bytes -- reduced by"
	echo "$ratio% from the timmed file, $ratio2% from the original file)"
else
	echo "(was $in_len, now $out_len, ratio: $ratio%)."
fi
