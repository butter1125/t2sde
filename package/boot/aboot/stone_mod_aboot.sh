# --- T2-COPYRIGHT-BEGIN ---
# t2/package/*/aboot/stone_mod_aboot.sh
# Copyright (C) 2004 - 2025 The T2 SDE Project
# SPDX-License-Identifier: GPL-2.0
# --- T2-COPYRIGHT-END ---
#
# [MAIN] 70 aboot Aboot Boot Loader Setup
# [SETUP] 90 aboot

create_kernel_list() {
	local idx=0 default=
	for x in vmlinuz `(cd /boot/; ls vmlinuz-*) | sort -Vr`; do
		[ "$default" ] || default=$(readlink /boot/$x)
		[ "$default" = "$x" ] && continue
		local ver=${x#vmlinuz}; ver=${ver#-}
		cat << EOT
$idx:${bootdev##*[^0-9]}$bootpath/$x initrd=$bootpath/initrd${ver:+-$ver} root=$rootdev ro
EOT
		((++idx))
	done
}

create_aboot_conf() {
	cat << EOT > /boot/aboot.conf

# /boot/aboot.conf created with the T2 SDE Aboot STONE module

EOT

	create_kernel_list >> /boot/aboot.conf

	gui_message "This is the new /boot/aboot.conf file:

$(< /boot/aboot.conf)"
}

aboot_install() {
	local boot=${bootdev%%[0-9]}
	local part=${bootdev#$boot}
	gui_cmd 'Installing Aboot' "echo 'Running swriteboot -c$part $boot /boot/bootlx'; swriteboot -c$part $boot /boot/bootlx"
}

device4()
{
	local dev="`grep \" $1 \" /proc/mounts | tail -n 1 |
	            cut -d ' ' -f 1`"
	if [ ! "$dev" ]; then # try the higher dentry
		local try="`dirname $1`"
		dev="`grep \" $try \" /proc/mounts | tail -n 1 | \
		      cut -d ' ' -f 1`"
	fi
	if [ -h "$dev" ]; then
	  echo "/dev/`readlink $dev`"
	else
	  echo $dev
	fi
}

realpath() {
	local dir="`dirname $1`"
	local file="`basename $1`"
	dir="`dirname $dir`/`readlink $dir`"
	dir="`echo $dir | sed 's,[^/]*/\.\./,,g'`"
	echo $dir/$file
}

main() {
	rootdev="`device4 /`"
	bootdev="`device4 /boot`"

	if [ "$rootdev" = "$bootdev" ]
	then bootpath=/boot; else bootpath=""; fi

	if [ ! -f /boot/aboot.conf ]; then
	  if gui_yesno "Aboot does not appear to be configured.
Automatically install Aboot now?"; then
	    create_aboot_conf
	    if ! aboot_install; then
	      gui_message "There was an error while installing Aboot."
	    fi
	  fi
	fi

	while

	gui_menu yaboot 'Aboot Boot Loader Setup' \
		"Root Device ........... $rootdev" "" \
		"Boot Device ........... $bootdev" "" \
		"Boot Path ............. $bootpath" "" \
		'' '' \
		'(Re-)Create aboot.conf with installed kernels' 'create_aboot_conf' \
		'(Re-)Install Aboot' 'aboot_install' \
		'' '' \
		"Edit /boot/aboot.conf (Config file)" \
			"gui_edit 'STONE Configuration' /boot/aboot.conf"
    do : ; done
}
