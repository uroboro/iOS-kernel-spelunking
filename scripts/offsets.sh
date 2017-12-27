#!//bin/sh

export PATH=$(pwd)/bin:$PATH

kernelcache=/tmp/kernel

function print_help() {
	self=$1
	echo "$self [kernel cache]"
	echo
	echo "Example:"
	echo "\t $self kernelcache.release.n102.dec"
}

# Finder functions

function address_kernel_map() {
	nm $1 | grep ' _kernel_map$' | awk '{ print "0x" $1 }'
}

function address_kernel_task() {
	nm $1 | grep ' _kernel_task$' | awk '{ print "0x" $1 }'
}

function address_bzero() {
	nm $1 | grep ' ___bzero$' | awk '{ print "0x" $1 }'
}

function address_bcopy() {
	nm $1 | grep ' _bcopy$' | awk '{ print "0x" $1 }'
}

function address_copyin() {
	nm $1 | grep ' _copyin$' | awk '{ print "0x" $1 }'
}

function address_copyout() {
	nm $1 | grep ' _copyout$' | awk '{ print "0x" $1 }'
}

function address_rootvnode() {
	nm $1 | grep ' _rootvnode$' | awk '{ print "0x" $1 }'
}

function address_kauth_cred_ref() {
	nm $1 | grep ' _kauth_cred_ref$' | awk '{ print "0x" $1 }'
}

function address_osserializer_serialize() {
	nm $1 | grep ' __ZNK12OSSerializer9serializeEP11OSSerialize$' | awk '{ print "0x" $1 }'
}

function address_host_priv_self() {
	host_priv_self_addr=$(nm $1 | grep host_priv_self | awk '{ print "0x" $1 }')
	r2 -q -e scr.color=false -c "pd 2 @ $host_priv_self_addr" $1 2> /dev/null | sed -n 's/0x//gp' | awk '{ print $NF }' | tr '[a-f]\n' '[A-F] ' | awk '{ print "obase=16;ibase=16;" $1 "+" $2 }' | bc | tr '[A-F]' '[a-f]' | awk '{ print "0x" $1 }'
}

function address_ipc_port_alloc_special() {
	r2 -e scr.color=false -q -c 'pd @ sym._convert_task_suspension_token_to_port' $1 2> /dev/null | sed -n 's/.*bl sym.func.\([a-z01-9]*\)/0x\1/p' | sed -n 1p
}

function address_ipc_kobject_set() {
	r2 -e scr.color=false -q -c 'pd @ sym._convert_task_suspension_token_to_port' $1 2> /dev/null | sed -n 's/.*bl sym.func.\([a-z01-9]*\)/0x\1/p' | sed -n 2p
}

function address_ipc_port_make_send() {
	r2 -e scr.color=false -q -c 'pd @ sym._convert_task_to_port' $1 2>/dev/null | sed -n 's/.*bl sym.func.\([a-z01-9]*\)/0x\1/p' | sed -n 1p
}

function address_rop_add_x0_x0_0x10() {
	r2 -q -e scr.color=true -c "\"/a add x0, x0, 0x10; ret\"" $1 2> /dev/null | grep -m 1 '0xff' | awk '{ print $1 }'
}

function address_rop_ldr_x0_x0_0x10() {
	r2 -q -e scr.color=true -c "\"/a ldr x0, [x0, 0x10]; ret\"" $1 2> /dev/null | grep -m 1 '0xff' | awk '{ print $1 }'
}

function address_zone_map() {
	string_addr=$(r2 -q -e scr.color=false -c 'iz~zone_init: kmem_suballoc failed' $1 2> /dev/null | awk '{ print $1 }' | sed 's/.*=//')
	xref1_addr=$(r2 -q -e scr.color=false -c "\"/c $string_addr\"" $1 2> /dev/null | awk '{ print $1 }')
	xref2_addr=$(r2 -q -e scr.color=false -c "\"/c $xref1_addr\"" $1 2> /dev/null | awk '{ print $1 }')
	addr=$(r2 -q -e scr.color=false -c "pd -8 @ $xref2_addr" $1 2> /dev/null | head -n 2 | grep 0x | awk '{ print $NF }' | sed 's/0x//' | tr '[a-f]\n' '[A-F] ' | awk '{ print "obase=16;ibase=16;" $1 "+" $2 }' | bc | tr '[A-F]' '[a-f]')
	echo "0x$addr"
}

function address_chgproccnt() {
	priv_check_cred_addr=$(nm $1 | grep ' _priv_check_cred$' | awk '{ print "0x" $1 }')
	r2 -q -e scr.color=false -c "pd 31 @ $priv_check_cred_addr" $1 2> /dev/null | tail -n1 | awk '{ print $1 }'
}

function address_iosurfacerootuserclient_vtab() {
	joker -K com.apple.iokit.IOSurface $1 &> /dev/null
	if [ ! -f /tmp/com.apple.iokit.IOSurface.kext ]; then
		echo "[#] Coudn't extract IOSurface kext. Bailing."
		exit 1
	fi
	kext=/tmp/com.apple.iokit.IOSurface.kext
	dump=/tmp/hexdump.txt

	# Get __DATA_CONST.__const offset and size
	data_const_const=$(r2 -q -e scr.color=false -c 'S' $kext 2> /dev/null | grep '__DATA_CONST.__const' | tr ' ' '\n' | grep '=')
	va=$(echo $data_const_const | tr ' ' '\n' | sed -n 's/va=//p')
	sz=$(echo $data_const_const | tr ' ' '\n' | sed -n 's/^sz=//p')

	# Dump hex to tmp file
	r2 -q -e scr.color=false -c "s $va; pxr $sz" $kext 2> /dev/null | awk '{ print $1 " " $2 }' > $dump
	IFS=$'\n' read -d '' -r -a hd < $dump
	lines=$(wc -l $dump | awk '{ print $1 }')

	# Go through each line, check if there are 2 consecutive zeros
	found=0
	for (( i = 1; i < $lines; i++ )); do
		# First zero
		zero1=$(echo ${hd[$i]} | awk '{ print $2 }')
		# Second zero
		zero2=$(echo ${hd[$((i+1))]} | awk '{ print $2 }')
		if [ "$zero1" == "0x0000000000000000" -a "$zero2" == "0x0000000000000000" ]; then
			# vtable offset
			offset=$(echo ${hd[$i+2]} | awk '{ print $1 }')
			# echo "found possible offset at $offset"

			# 8th pointer after vtable start
			pointer8=$(echo ${hd[$((i+2+7))]} | awk '{ print $2 }')
			if [ -z "$pointer8" ]; then
				break
			fi

			# Retrieve class name
			cmd_lookup=$(r2 -q -e scr.color=false -c "pd 3 @ $pointer8" $kext 2> /dev/null | awk '{ print $NF }' | tr '\n' ' ' | awk '{ print $1 "; " $2 }')
			second_to_last=$(r2 -q -e scr.color=true -c "\"/c $cmd_lookup\"" $kext 2>/dev/null | tail -n 2 | head -n 1 | awk '{ print $1 }')
			class_addr=$(r2 -q -e scr.color=false -c "pd 3 @ $second_to_last" $kext 2> /dev/null | tail -n 2 | awk '{ print $NF }' | tr '\n' ' ' | awk '{ print $1 "+" $2 }')
			name=$(r2 -q -e scr.color=false -c "ps @ $class_addr" $kext 2> /dev/null | sed 's/[^a-zA-Z]//g')

			if [[ ! -z "$name" && "$name" == "IOSurfaceRootUserClient" ]]; then
				# Done!
				found=1
				echo "$offset"
				rm $kext $dump
				return 0
			fi
		fi
	done
	rm $kext $dump

	echo "0xdeadbabe8badf00d"
}

# Main program

if [ $# -eq 1 ]; then
	kache="$1"
else
	print_help $0
	exit 0
fi

if [[ $(du $kache | awk '{ printf $1 }') == "0" ]]; then
	echo "[#] Empty file. Bailing"
	return 1
fi

strings $kernelcache | grep 'Darwin K'
echo "[#] Working..."

offset_zone_map=$(address_zone_map $kernelcache)
offset_kernel_map=$(address_kernel_map $kernelcache)
offset_kernel_task=$(address_kernel_task $kernelcache)
offset_host_priv_self=$(address_host_priv_self $kernelcache)
offset_bzero=$(address_bzero $kernelcache)
offset_bcopy=$(address_bcopy $kernelcache)
offset_copyin=$(address_copyin $kernelcache)
offset_copyout=$(address_copyout $kernelcache)
offset_chgproccnt=$(address_chgproccnt $kernelcache)
offset_rootvnode=$(address_rootvnode $kernelcache)
offset_kauth_cred_ref=$(address_kauth_cred_ref $kernelcache)
offset_ipc_port_alloc_special=$(address_ipc_port_alloc_special $kernelcache)
offset_ipc_kobject_set=$(address_ipc_kobject_set $kernelcache)
offset_ipc_port_make_send=$(address_ipc_port_make_send $kernelcache)
offset_iosurfacerootuserclient_vtab=$(address_iosurfacerootuserclient_vtab $kernelcache)
offset_rop_add_x0_x0_0x10=$(address_rop_add_x0_x0_0x10 $kernelcache)
offset_osserializer_serialize=$(address_osserializer_serialize $kernelcache)
offset_rop_ldr_x0_x0_0x10=$(address_rop_ldr_x0_x0_0x10 $kernelcache)

rm $kernelcache

echo "OFFSET_ZONE_MAP                        = $offset_zone_map;"
echo "OFFSET_KERNEL_MAP                      = $offset_kernel_map;"
echo "OFFSET_KERNEL_TASK                     = $offset_kernel_task;"
echo "OFFSET_REALHOST                        = $offset_host_priv_self;"
echo "OFFSET_BZERO                           = $offset_bzero;"
echo "OFFSET_BCOPY                           = $offset_bcopy;"
echo "OFFSET_COPYIN                          = $offset_copyin;"
echo "OFFSET_COPYOUT                         = $offset_copyout;"
echo "OFFSET_ROOT_MOUNT_V_NODE               = $offset_rootvnode;"
echo "OFFSET_CHGPROCCNT                      = $offset_chgproccnt;"
echo "OFFSET_KAUTH_CRED_REF                  = $offset_kauth_cred_ref;"
echo "OFFSET_IPC_PORT_ALLOC_SPECIAL          = $offset_ipc_port_alloc_special;"
echo "OFFSET_IPC_KOBJECT_SET                 = $offset_ipc_kobject_set;"
echo "OFFSET_IPC_PORT_MAKE_SEND              = $offset_ipc_port_make_send;"
echo "OFFSET_IOSURFACEROOTUSERCLIENT_VTAB    = $offset_iosurfacerootuserclient_vtab;"
echo "OFFSET_ROP_ADD_X0_X0_0x10              = $offset_rop_add_x0_x0_0x10;"
echo "OFFSET_OSSERIALIZER_SERIALIZE          = $offset_osserializer_serialize;"
echo "OFFSET_ROP_LDR_X0_X0_0x10              = $offset_rop_ldr_x0_x0_0x10;"
