#!/bin/sh

KEYMAP_FILE_PATH="/usr/share/X11/xkb/tizen_key_layout.txt"
BASE_KEYSYM="0x10090000"
TARGET_HEADER_FILE="./xkbcommon/tizen_keymap.h"
TEMP_TEXT_FILE="./temp_file.txt"
NEW_DEFINE_SYM_FILE="./new_define_sym.txt"
KEYMAP_HEADER_FILE="./xkbcommon/xkbcommon-keysyms.h"
cout=1
BASE_KEYSYM_DEC=`python -c "print int('$BASE_KEYSYM', 16)"`

if [ -e ${KEYMAP_FILE_PATH} ]
then
	echo "${TIZEN_PROFILE} have a key layout file: ${KEYMAP_FILE_PATH}"
else
	echo "${TIZEN_PROFILE} doesn't have a key layout file: ${KEYMAP_FILE_PATH}"
	exit
fi

echo "Generate a tizen keymap header file"
touch $NEW_DEFINE_SYM_FILE

while read KEYNAME KEYCODE
do
	KEYSYM="XKB_KEY_${KEYNAME}"
	grep -rn "${KEYSYM}" $KEYMAP_HEADER_FILE > $TEMP_TEXT_FILE
	FINDED_DEFINE=`cat temp_file.txt | awk '{print $2}'`

	BOOL_FOUND_SYM=false
	for SEARCH_SYM in ${FINDED_DEFINE}
	do
		if [ "$SEARCH_SYM" = "$KEYSYM" ]
		then
			BOOL_FOUND_SYM=true
		break
		fi
	done
	BOOL_DUPLICATED_SYM=false
	if [ "$BOOL_FOUND_SYM" = false ]
	then
		while read KEYSYM_NEW
		do
			if [ "$KEYSYM_NEW" = "$KEYSYM" ]
			then
				BOOL_DUPLICATED_SYM=true
			break
			fi
		done < ${NEW_DEFINE_SYM_FILE}
		if [ "$BOOL_DUPLICATED_SYM" = false ]
		then
			echo "${KEYSYM}" >> $NEW_DEFINE_SYM_FILE
		fi
	fi
done < ${KEYMAP_FILE_PATH}

sed -i '$s/#endif//g' ${KEYMAP_HEADER_FILE}
echo "/**************************************************************" >> ${KEYMAP_HEADER_FILE}
echo " * These keys defined for tizen platform." >> ${KEYMAP_HEADER_FILE}
echo " * Key symbols are defined by keymap builder." >> ${KEYMAP_HEADER_FILE}
echo " */" >> ${KEYMAP_HEADER_FILE}

while read KEYNAME
do
	KEYSYM_DEC=$(echo $BASE_KEYSYM_DEC $cout | awk '{print $1 + $2}')
	KEYSYM=$(printf "%x" $KEYSYM_DEC)
	echo -en "#define ${KEYNAME}\t\t0x$KEYSYM\n" >> ${KEYMAP_HEADER_FILE}
	cout=$(echo $cout 1 | awk '{print $1 + $2}')
done < ${NEW_DEFINE_SYM_FILE}

echo "" >> ${KEYMAP_HEADER_FILE}
echo "" >> ${KEYMAP_HEADER_FILE}
echo "#endif" >> ${KEYMAP_HEADER_FILE}

rm $NEW_DEFINE_SYM_FILE
rm $TEMP_TEXT_FILE
