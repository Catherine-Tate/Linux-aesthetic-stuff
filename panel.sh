#!/usr/bin/env bash
#
# z3bra - (c) wtfpl 2014
# Fetch infos on your computer, and print them to stdout every second.

clock() {
    date '+%Y-%m-%d %H:%M'
}

battery() {
    BATC=/sys/class/power_supply/BAT0/capacity
    BATS=/sys/class/power_supply/BAT0/status

    test "`cat $BATS`" = "Charging" && echo -n '+' || echo -n '-'

    sed -n p $BATC
}

volume() {
	awk -F"[][]" '/dB/ { print $2 }' <(amixer sget Master)
	awk -F"[][]" '/dB/ { print $6 }' <(amixer sget Master)
}

cpuload() {
    LINE=`ps -eo pcpu |grep -vE '^\s*(0.0|%CPU)' |sed -n '1h;$!H;$g;s/\n/ +/gp'`
    bc <<< $LINE
}

memused() {
    read t f <<< `grep -E 'Mem(Total|Free)' /proc/meminfo |awk '{print $2}'`
    bc <<< "scale=2; 100 - $f / $t * 100" | cut -d. -f1
}

# check and output the network connection state
network() {
	# The following assumes you have 3 interfaces: loopback, ethernet, wifi
	read lo int1 <<< `ip link | sed -n 's/^[0-9]: \(.*\):.*$/\1/p'`
	# iwconfig returns an error code if the interface tested has no wireless
	# extensions
	#if iwconfig $int1 >/dev/null 2>&1; then
	#    wifi=$int1
	#    eth0=$int2
	#else 
	#    wifi=$int2
	#    eth0=$int1
	#fi
	
	wifi = $int1

	# in case you have only one interface, just set it here:
	# int=eth0
	# this line will set the variable $int to $eth0 if it's up, and $wifi
	# otherwise. I assume that if ethernet is UP, then it has priority over
	# wifi. If you have a better idea, please share :)
	ip link show $eth0 | grep 'state UP' >/dev/null && int=$eth0 || int=$wifi
	# just output the interface name. Could obviously be done in the 'ping'
	# query
	echo -n "$int"
	# Send a single packet, to speed up the test. I use google's DNS 8.8.8.8,
	# but feel free to use any ip address you want. Be sure to put an IP, not a
	# domain name. You'll bypass the DNS resolution that can take some precious
	# miliseconds ;)
	# synj - added -s1 to save data on metered connections
	#ping -c1 -s1 8.8.8.8 >/dev/null 2>&1 && echo "connected" || echo "disconnected"
}


groups() {
    cur=`xprop -root _NET_CURRENT_DESKTOP | awk '{print $3}'`
    tot=`xprop -root _NET_NUMBER_OF_DESKTOPS | awk '{print $3}'`

    for w in `seq 0 $((cur - 1))`; do line="${line}="; done
    line="${line}|"
    for w in `seq $((cur + 2)) $tot`; do line="${line}="; done
    echo $line
}

tags() {
	wm_infos=""
	TAGS=( $(herbstclient tag_status $monitor) )
	for i in "${TAGS[@]}" ; do
		case ${i:0:1} in
				'#')
					# focused occupied desktop
					wm_infos="${wm_infos}${AC}${goto}%{B#efefef}%{F#000d18} {${i:1}${AB}} ${AE}%{-u}%{B-}%{F-}"
					;;
				'+')
					# focused free desktop
					wm_infos="${wm_infos}${AC}${goto}{B#efefef}%{F#93ce9e} {${i:1}${AB}} ${AE}%{-u}%{B-}%{F-}"
					;;
				'!')
					# focused urgent desktop
					wm_infos="${wm_infos}${AC}${goto} {${i:1}${AB}} ${AE}%{-u}%{B-}%{F-}"
					;;
				':')
					# occupied desktop
					wm_infos="${wm_infos}${AC}${goto} [${i:1}${AB}] ${AE}%{-u}%{B-}%{F-}"
					;;
				 *)
					# free desktop
					wm_infos="${wm_infos}${AC}${goto}%{F#93ce9e} [${i:1}${AB}] ${AE}%{-u}%{B-}%{F-}"
					;;
			esac
			shift
		done
	echo "$wm_infos"
	sleep .3

}

#nowplaying() {
#    cur=`mpc current`
#    # this line allow to choose whether the output will scroll or not
#    test "$1" = "scroll" && PARSER='skroll -n20 -d0.5 -r' || PARSER='cat'
#    test -n "$cur" && $PARSER <<< $cur || echo "- stopped -"
#}

# This loop will fill a buffer with our infos, and output it to stdout.
while :; do
    buf=""

    buf="%{F-}${buf} $(tags)"

    #buf="${buf} [$(groups)]   --  "
    buf="${buf} %{c}%{F#efefef}$(clock)" 
    buf="${buf} %{r}%{F#8cd0d3} CPU: $(cpuload)%% | "
    #buf="${buf} RAM: $(memused)%% -"
    buf="${buf} VOL: $(volume) | "
    #buf+="${buf} NET: $(network) |"
    #buf="${buf} MPD: $(nowplaying)"
    buf="${buf} BAT: $(battery)%"

    echo $buf
    # use `nowplaying scroll` to get a scrolling output!
    sleep .3 # The HUD will be updated every second
done
