#!/bin/bash

FILE=$1
 

#echo "$DATA"
#echo "$HORA"
#echo "$MSG"

for i in `grep -v "SENTIDO" "$FILE" | tr ' ' '_'`;do
	
	DATA=`echo "$i" | cut -d, -f3 | tr '/' '-'`
	HORA=`echo "$i" | cut -d, -f4`
	MSG=`echo "$i" | cut -d, -f5 | tr -d '\@' | tr '_' ' '`

	echo "$MSG"

	./ponto.sh -i "$MSG" $DATA $HORA
#	sleep 1
done
