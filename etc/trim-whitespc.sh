#!/bin/bash

# This script strips off most of the trailing whitespace
# from the input file, but because it's one big, 1000-plus
# byte stream of printable PETSCII without line breaks,
# we need to scan the file and split it into lines
# by tracking what column of the screen we'd be on if we
# were printing, inserting RETURNs in place of the last
# space char on the line

verbose=0
if [[ "$1" == "-v" ]] ; then
	shift
	verbose=1
fi

cols=$1			# Assume file is for this-many-column screen
in_file=$2		# input filename
out_file=$3		# final compressed output file

tmpdir="/tmp/mp-trim-ws-compress-tmp"
lined_file="$tmpdir/split-to-lines-$cols.hex"

mkdir -p "$tmpdir"
rm -f "$lined_file" "$out_file"

echo "Trimming excess whitespace from $in_file ..."

IFS=
LANG=C

exec 6< "$in_file"
touch "$lined_file"

column_counter=0
line_counter=1

while read -u 6 -n 1 -d '' -r bin ; do
	printf -v d %d \'$bin  # converts the raw file byte to decimal
	hex=$(printf "%01.2x" $d)

	if [ -z "$d" ] ; then
		break
	fi

	if [[ "0x$hex" == "0x0d" || "0x$hex" == "0x8d" ]] ; then # return or shift-return
		column_counter=1
	elif [[ ( "0x$hex" > "0x1f"  &&  "0x$hex" < "0x80" ) 
	  || "0x$hex" > "0x9f" || "0x$hex" == "0x1d" ]] ; then  # 0x1d = cursor-right
		(( column_counter++ ))
	elif [[ "0x$hex" == "0x14" || "0x$hex" == "0x9d" ]] ; then # cursor-left or delete
		(( column_counter-- ))
	fi
	
	if (( column_counter == cols )) ; then
		if (( verbose )) ; then
			echo "Line $line_counter ended with character \$$hex."
		fi
		
		if [[ "0x$hex" == "0x20" ]] ; then
			if (( line_counter < 25 )) ; then
				hex="0d"
				if (( verbose )) ; then
					echo "Replaced a trailing space with RETURN at end of line $line_counter."
				fi
			else
				hex="0d"
				if (( verbose )) ; then
					echo "Removed trailing space at end of line 25"
				fi
			fi
		fi
		column_counter=0
		(( line_counter++ ))
	fi
	echo -e -n "$hex " >> "$lined_file"
done

exec 6<&-

	# trim ends of lines
sed -e 's/\(20 \)*0d/0d/g' "$lined_file"  |
	# turn lines of only-spaces into just the finishing RETURNs
	sed -e 's/^\(20 \)*$/0d/'             |
	# turn the line-ified data back into printable PETSCII.
	xxd -r -p > "$out_file"

# trim the last two bytes from the file, they'll always be a RETURN and a color code
truncate -s -2 "$out_file"

in_len=$(wc -c < "$in_file")
trim_len=$(wc -c < "$out_file")
trim_change=$(( in_len-trim_len ))

ratio=$(printf "%.1f"  $(bc <<< "100 - ($trim_len/$in_len)*100"))

echo "TRIM WHITESPACE: input file shortened by ${trim_change#-} bytes."
echo "(was $in_len, trimmed to $trim_len, ratio: $ratio%)."
