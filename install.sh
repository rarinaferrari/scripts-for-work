#! /bin/bash


set -e
for i in ./*.apk;
do
	if [[ -f $i ]];
	then
		echo "$i"
		adb install $i;

		echo "-----------"
	else
		continue
	fi
done

