# --- T2-COPYRIGHT-BEGIN ---
# t2/package/*/stone/stone_mod_general.sh
# Copyright (C) 2004 - 2025 The T2 SDE Project
# Copyright (C) 1998 - 2003 ROCK Linux Project
# SPDX-License-Identifier: GPL-2.0
# --- T2-COPYRIGHT-END ---
#
# [MAIN] 10 general,main Various general system configurations
# [SETUP] 10 general set_tmarea
# [SETUP] 15 general set_dtime
# [SETUP] 20 general set_locale
# # [SETUP] 30 general set_vcfont

set_keymap() {
	keymap=$(ls -l /etc/default.keymap 2> /dev/null | sed 's,.*/,,')
	[ -z "$keymap" ] && keymap="none" ; keymap="${keymap%.map.gz}"

	# ReneR: Attention: although this reads i386, this is nowadays valid
	#        for all (? - at least also on PowerPC where this was a long ugly
	#        bug in ROCK times) - the input layer does pass "unified" events ...
	mapdir="`echo /usr/share/kbd/keymaps/i386`"

	cmd="gui_menu 'general_keymap' 'Select one of the following keyboard mappings.'"
	if [ "$keymap" != none ]; then
		cmd="$cmd 'Current: $keymap' 'loadkeys defkeymap'"
	fi
	cmd="$cmd 'none (kernel defaults)' 'rm -f /etc/default.keymap ; loadkeys defkeymap'"

	cmd="$cmd $( find $mapdir -type f ! -path '*/include/*' -name '*.map.gz' -printf '%P\n' | sed 's,\(.*\)/\(.*\).map.gz$,"\2	(\1)" "ln -sf '$mapdir'/& /etc/default.keymap ; loadkeys \2",' | expand -t30 | sort | tr '\n' ' ')"

	eval "$cmd"
}

set_vcfont() {
	vcfont=$(ls -l /etc/default.vcfont 2> /dev/null | sed 's,.*/,,')
	if [ -z "$vcfont" ]; then vcfont="none"
	else vcfont="`echo $vcfont | sed -e "s,\.\(fnt\|psf.*\)\.gz$,,"`"; fi
	fontdir="/usr/share/kbd/consolefonts"

	cmd="gui_menu 'general_vcfont' 'Select one of the following console fonts.'"
	if [ "$vcfont" != none ]; then
		cmd="$cmd 'Current: $vcfont' 'setfont'"
	fi
	cmd="$cmd 'none (kernel defaults)' 'rm -f /etc/default.vcfont ; setfont'"

	cmd="$cmd $( find $fontdir -type f \( -name '*.fnt.gz' -or -name '*.psf*.gz' \) -printf '%P\n' | sed 's,\(.*\).\(fnt\|psf.*\)\.gz$,"\1" "ln -sf '$fontdir'/& /etc/default.vcfont ; setfont \1",' | expand -t30 | sort | tr '\n' ' ')"

	eval "$cmd"
}

store_kbd(){
	if [ -f /etc/conf/kbd ]; then
		sed -e "s/kbd_rate=.*/kbd_rate=$kbd_rate/" \
		    -e "s/kbd_delay=.*/kbd_delay=$kbd_delay/" < /etc/conf/kbd \
		  > /etc/conf/kbd.tmp
		grep -q kbd_rate= /etc/conf/kbd.tmp || echo kbd_rate=$kbd_rate \
		  >> /etc/conf/kbd.tmp
		grep -q kbd_delay= /etc/conf/kbd.tmp || echo kbd_delay=$kbd_delay \
		  >> /etc/conf/kbd.tmp
		mv /etc/conf/kbd.tmp /etc/conf/kbd
	else
		echo -e "kbd_rate=$kbd_rate\nkbd_delay=$kbd_delay" \
		  > /etc/conf/kbd
	fi
	[ "$kbd_rate" -a "$kbd_delay" ] && kbdrate -r $kbd_rate -d $kbd_delay
}

set_kbd_rate() {
	gui_input "Set new console keyboard auto-repeat rate" \
		  "$kbd_rate" "kbd_rate"
	store_kbd
}

set_kbd_delay() {
	gui_input "Set new console keyboard auto-repeat delay" \
		  "$kbd_delay" "kbd_delay"
	store_kbd
}

store_con() {
	if [ -f /etc/conf/console ]; then
		sed -e "s/con_term=.*/con_term=$con_term/" \
		    -e "s/con_blank=.*/con_blank=$con_blank/" \
		    -e "s/con_blength=.*/con_blength=$con_blength/" \
		    -i /etc/conf/console
	fi
	touch /etc/conf/console # make sure the file exists
	grep -q con_term= /etc/conf/console ||
	  echo con_term=$con_term >> /etc/conf/console
	grep -q con_blank= /etc/conf/console ||
	  echo con_blank=$con_blank >> /etc/conf/console
	grep -q con_blength= /etc/conf/console ||
	  echo con_blength=$con_blength >> /etc/conf/console

	[ "$con_term" -a "$con_blank" -a "$con_blength" ] &&
	  setterm -term $con_term -blank $con_blank -blength $con_blength \
	          > /dev/console
}

set_con_term() {
	gui_input "Set new console screen terminal type" \
		  "$con_term" "con_term"
	store_con
}

set_con_blank() {
	gui_input "Set new console screen blank interval" \
		  "$con_blank" "con_blank"
	store_con
}

set_con_blength() {
	gui_input "Set new console screen beep interval" \
		  "$con_blength" "con_blength"
	store_con
}

set_tmzone() {
	tz="$( ls -l /etc/localtime | cut -f8 -d/ )"
	cmd="gui_menu 'general_tmzone' 'Select one of the following time zones.'"

	if [ -n "$tz" -a -f ../usr/share/zoneinfo/$1/$tz ]; then
		cmd="$cmd 'Current: $tz' 'ln -sf ../usr/share/zoneinfo/$1/$tz \
			/etc/localtime'"
	fi
	cmd="$cmd $( grep "$1/" /usr/share/zoneinfo/zone.tab | cut -f3 | \
		cut -f2 -d/ | sort -u | tr '\n' ' ' | sed 's,[^ ]\+,& '`
		`'"ln -sf ../usr/share/zoneinfo/$1/& /etc/localtime",g' )"

	eval "$cmd"
}

set_tmarea() {
	tz="$( ls -l /etc/localtime | cut -f7 -d/ )"
	cmd="gui_menu 'general_tmarea' 'Select one of the following time areas.'"

	cmd="$cmd 'Current: $tz' 'if set_tmzone $tz; then tzset=1; fi'"
	cmd="$cmd $( grep '^[^#]' /usr/share/zoneinfo/zone.tab | cut -f3 | \
		cut -f1 -d/ | sort -u | tr '\n' ' ' | sed 's,[^ ]\+,& '`
		`'"if set_tmzone &; then tzset=1; fi",g' )"

	tzset=0
	while eval "$cmd" && [ $tzset = 0 ] ; do : ; done
}

set_dtime() {
  local set=0
  while [ $set = 0 ]; do
	dtime="`date '+%m-%d %H:%M %Y'`" ; newdtime="$dtime"
	[ -f /etc/conf/clock ] && . /etc/conf/clock
	[ "$clock_tz" != localtime ] && clock_tz=utc
	gui_input "Set new date and time (MM-DD hh:mm YYYY, $clock_tz)" \
	          "$dtime" "newdtime"
	if [ "$dtime" != "$newdtime" ]; then
		echo "Setting new date and time ($newdtime) ..."
		if ! date "$( echo $newdtime | sed 's,[^0-9],,g' )"; then
			gui_message "Error setting time, invalid timespec?"
		else
			set=1
		fi
		hwclock --systohc --$clock_tz
	else
		set=1
	fi
  done
}

set_locale_sub() {
	if [ "$1" != "none" ]; then
		localedef -i ${1%.*} -c -f ${1#*.} $1
		echo "export LANG='$1'" > /etc/profile.d/locale
	else
		rm -f /etc/profile.d/locale
	fi
}

set_locale() {
	unset LANG ; [ -f /etc/profile.d/locale ] && . /etc/profile.d/locale
	locale="${LANG:-none}" ; cmd="gui_menu 'general_locale' 'Select one of the following locales.'"

	if [ "$locale" != none ]; then
		title=$(grep -a ^title /usr/share/i18n/locales/${locale%.*} | \
		  sed -e 's,.*"\(.*\)".*,\1,g' -e "s,',�,g")
		x="$( echo -e "Current: ${title:0:41}\t$locale" | expand -t52 )"
		cmd="$cmd '$x' 'true'"
	fi
	x="$( echo -e "none\tnone" | expand -t52 )"
	cmd="$cmd '$x' 'set_locale_sub none'"

	x="$( echo -e "POSIX\tC" | expand -t52 )"
	cmd="$cmd '$x' 'set_locale_sub C' $(
		grep -Ha ^title /usr/share/i18n/locales/* | \
		  sed -e 's,.*/\(.*\):.*"\(.*\)",\1\t\2,g' \
		      -e "s,',�,g" | while read key title; do
			key="$key.UTF-8"
			echo "'${title:0:50}	$key' 'set_locale_sub $key'" | expand -t53 | tr '\n' ' '
		done
	)"

	eval "$cmd"
}

main() {
    while
	unset LANG ; [ -f /etc/profile.d/locale ] && . /etc/profile.d/locale
	locale="${LANG:-none}" ; tz="$( ls -l /etc/localtime | cut -f7- -d/ )"
	keymap=$(ls -l /etc/default.keymap 2> /dev/null | sed 's,.*/,,')
	[ "$keymap" ] || keymap="none" ; keymap="${keymap%.map.gz}"
	vcfont=$(ls -l /etc/default.vcfont 2> /dev/null | sed 's,.*/,,')
	if [ -z "$vcfont" ]; then vcfont="none"
	else vcfont="`echo $vcfont | sed -e "s,\.\(fnt\|psf.*\)\.gz$,,"`"; fi
	dtime="`date '+%m-%d %H:%M %Y'`"
	[ -f /etc/conf/kbd ] && . /etc/conf/kbd
	[ "$kbd_rate" ] || kbd_rate=30
	[ "$kbd_delay" ] || kbd_delay=250
	[ -f /etc/conf/console ] && . /etc/conf/console
	[ "$con_term" ] || con_term=linux
	[ "$con_blank" ] || con_blank=0
	[ "$con_blength" ] || con_blength=0

	gui_menu general 'Various general system configurations' \
		"Set console keyboard mapping ....... $keymap" "set_keymap" \
		"Set console screen font ............ $vcfont" "set_vcfont" \
		"Set system-wide time zone .......... $tz"     "set_tmarea" \
		"Set date and time (utc/localtime) .. $dtime"  "set_dtime"  \
		"Set system-wide locale (language) .. $locale" "set_locale" \
		"Set console keyboard repeat rate ... $kbd_rate" "set_kbd_rate" \
		"Set console keyboard repeat delay .. $kbd_delay" "set_kbd_delay" \
		"Set console screen terminal type ... $con_term" "set_con_term" \
		"Set console screen blank interval .. $con_blank" "set_con_blank" \
		"Set console screen beep interval ... $con_blength" "set_con_blength" \
		"Run the (daily) 'cron.run' script now" "cron.run"
    do : ; done
}
