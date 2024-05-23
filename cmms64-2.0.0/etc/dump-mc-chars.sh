#!/bin/bash

echo "                   ________"
declare int n=0
xxd -s 2 -c 1 -ps -b "$*" | cut -f 1-2 -d " " | while read line; do
n=$((n+1))

echo -n $line

echo -n " |"

echo -n $line |sed "s/.......: // ; s/../& /g" \
|sed "s/00 /  /g ;  s/01 /██/g ;  s/10 /▒▒/g ; s/11 /░░/g"
echo "|"

if [ $n = 8 ] ; then {
n=0
echo "                   ¯¯¯¯¯¯¯¯"
echo "                   ________"
}
fi

done
