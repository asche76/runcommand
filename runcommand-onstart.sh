#!/usr/bin/env bash
#title           :	runcommand-onstart.sh
#description     :	This script perform the following
#					Determines if the game being run is a console or an arcade/fba
#					For arcades, it will programatically determine the resolution based on resolution.ini file
#					For consoles, hdmi_timings can be set based on emulator or system
#					Dynamically creates the game_name.zip.cfg file and sets the custom_viewport_height
#					Dynamically add these parameters (video_allow_rotate = "true" and video_rotation = 1) for vertical games
#					vertical.txt contains all the mame 0.184 vertical games
#					Ability to set custom_viewport_width for arcades/fba
#					Fix arcade custom_viewport_width for 320x224 and 320x240 resolutions
#					Added amiga and C64 support
#	                Automatically set custom_viewport_y to center vertically (Removed on 0.7.1)
#					Added support for 480 height arcade games like tapper
#					All console and arcade will default to 1600x240 resolution
#					Disable resolution change for non libretto cores
#					Added support for 448 height arcade games like popeye
#					Added support for 254 height arcade games like mk3
#					Arcade/FBA - Set custom_viewport_width to be rom_resolution_width multiplied closest to 1600
#					Removed text output when running scripts
#					Reverted hdmi_timings to previous version
#					Removed all logging
#					Default non supported emulators to 320x240
#author		 	 :	Michael Vencio
#date            :	2019-05-25
#version         :	0.8.3
#notes           :	For advance users only and would need to be tweaked 
#					to cater to your needs and preference
#					resolution.ini (0.184) file needed http://www.progettosnaps.net/renameset/
#===============================================================================================================


# get the system name
system=$1

# get the emulator name
emul=$2
emul_lr=${emul:0:2}

# get the full path filename of the ROM
rom_fp=$3
rom_bn=$3

# Game or Rom name
rom_bn="${rom_bn%.*}"
rom_bn="${rom_bn##*/}"

# Determine if arcade or fba then determine resolution, set hdmi_timings else goto console section
if [[ "$system" == "arcade" ]] || [[ "$system" == "fba" ]] || [[ "$system" == "mame-libretro" ]] ; then
	# get the line number matching the rom
	rom_ln=$(tac /opt/retropie/configs/all/resolution.ini | grep -w -n $rom_bn | cut -f1 -d":")

	# get resolution of rom
	rom_resolution=$(tac /opt/retropie/configs/all/resolution.ini | sed -n "$rom_ln,$ p" | grep -m 1 -F '[') 
	rom_resolution=${rom_resolution#"["}
	rom_resolution=${rom_resolution//]}
	rom_resolution=$(echo $rom_resolution | sed -e 's/\r//g')
	rom_resolution_width=$(echo $rom_resolution | cut -f1 -d"x")
	rom_resolution_height=$(echo $rom_resolution | cut -f2 -d"x")
	# Set rom_resolution_height for 480p and 448p roms
	if [ $rom_resolution_height == "480" ]; then
		rom_resolution_height="240"
	elif [ $rom_resolution_height == "448" ]; then
		rom_resolution_height="224"		
	fi	
	
	# Create rom_name.cfg
	if ! [ -f "$rom_fp"".cfg" ]; then 
		touch "$rom_fp"".cfg" 
	fi
	
	# Set custom_viewport_height
	if ! grep -q "custom_viewport_height" "$rom_fp"".cfg"; then
		echo -e "custom_viewport_height = ""\"$rom_resolution_height\"" >> "$rom_fp"".cfg" 2>&1
	fi
	
	# determine if vertical  
	if grep -w "$rom_bn" /opt/retropie/configs/all/vertical.txt ; then 
		# Add vertical parameters (video_allow_rotate = "true")
		if ! grep -q "video_allow_rotate" "$rom_fp"".cfg"; then
			echo -e "video_allow_rotate = \"true\"" >> "$rom_fp"".cfg" 2>&1
		fi
		# Add vertical parameters (video_rotation = 1)
		if ! grep -q "video_rotation" "$rom_fp"".cfg"; then
			echo -e "video_rotation = \"1\"" >> "$rom_fp"".cfg" 2>&1
		fi	
	fi

	# set the custom_viewport_width 
	if ! grep -q "custom_viewport_width" "$rom_fp"".cfg"; then 
		echo -e "custom_viewport_width = ""\"1600\"" >> "$rom_fp"".cfg"  2>&1
	fi
fi

# Use 1600 resolution for libretto cores
if [[ "$emul_lr" == "lr" ]]; then
	## some custom res timimg conditions for several arcade games: ###########
	## this is made for use with fba emulator
	## many older fba drivers doesn't respect exact video timings 
	## (e.g. truxton fba runs best with 60hz and not the genuine 57.6hz which is perfect for mame2003+)
	## newer drivers e.g. raiden2, twin cobra / flying shark (twincobr.cpp) / r-type(m72.cpp) runs well and respect the exact genuine arcade timing 
	
	##########################################
	# set hdmi_timings based on rom_resolution
	##########################################
	if [ "$rom_resolution" == "384x256" ] || [ "$rom_resolution" == "256x256" ] || [ "$rom_resolution" == "240x252" ] || [ "$rom_resolution" == "240x248" ]; then
		if grep -w "$rom_bn" /opt/retropie/configs/all/m72-5502.txt ; then
			#if [ "$rom_bn" == "rtype" ] || [ "$rom_bn" == "rtypew" ] || [ "$rom_bn" == "rtypeu" ] || [ "$rom_bn" == "rtypej" ]; then
		    ## r-type
			#vcgencmd hdmi_timings 1920 1 50 320 310 288 1 1 3 1 0 0 0 55 0 41900000 1
			###vcgencmd hdmi_timings 1920 1 56 176 176 268 1 6 8 8 0 0 0 55.0 0 37131600 1
			### ok soweit
			#vcgencmd hdmi_timings 1920 1 80 260 300 266 1 6 8 8 0 0 0 55.0 0 40550400 1
			## exact refresh
			#vcgencmd hdmi_timings 1920 1 120 192 358 256 1 8 5 18 0 0 0 55.017606 0 41054137.6 1
			#vcgencmd hdmi_timings 1920 1 152 247 280 240 1 3 7 12 0 0 0 60 0 40860000 1
			### real hori khz 15.625 khz
			#vcgencmd hdmi_timings 1920 1 120 192 368 256 1 8 6 14 0 0 0 55.017606 0 40625000.27 1
			#vcgencmd hdmi_timings 1536 1 60 240 260 256 1 10 4 14 0 0 0 55 0 32739520 1
			### 
			vcgencmd hdmi_timings 1536 1 100 160 300 256 1 8 2 19 0 0 0 55 0 32854800 1
			#vcgencmd hdmi_timings 1536 1 50 300 250 256 1 9 4 16 0 0 0 55 0 33481800 1
			tvservice -e "DMT 87"
			fbset -depth 8 && fbset -depth 16 -xres 1536 -yres 256
			# set the custom_viewport_width 
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for 384x256 timings" >&2		
			else
				echo -e "custom_viewport_width = \"1536\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1536 for 384x256 timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade 384x256 timings" >&2
		elif [ "$rom_bn" == *mpatrol* ] || [ "$rom_bn" == *mranger* ]; then
			### moon patrol 
			#if [ "$rom_bn" == "mpatrol" ]; then
		    ## other 55hz games but with 240p !! + twin cobra
			### fast perfekt !!!
			#vcgencmd hdmi_timings 1920 1 50 250 250 256 1 3 4 14 0 0 0 56.6 0 38725154 1
			#vcgencmd hdmi_timings 1920 1 50 250 250 256 1 4 4 14 0 0 0 56.6 0 38864956 1
			##vcgencmd hdmi_timings 1920 1 50 250 250 256 1 4 4 14 0 0 0 56.5 0 38796290 1
			#vcgencmd hdmi_timings 1920 1 50 250 250 256 1 4 4 12 0 0 0 56.8 0 38721696 1
			#vcgencmd hdmi_timings 1920 1 50 250 250 256 1 4 4 13 0 0 0 56.8 0 38861992 1
			## ok soweit
			#vcgencmd hdmi_timings 1920 1 50 250 250 256 1 4 4 13 0 0 0 56.7 0 38793573 1
	        ## new exact?
			#vcgencmd hdmi_timings 1920 1 50 250 250 256 1 4 4 13 0 0 0 56.737589 0 38819291.02 1
			## porch from jochen/regamebox
			#vcgencmd hdmi_timings 1920 1 58 183 183 256 1 7 3 15 0 0 0 56.737589 0 37371007.32 1
			## not bad
			#vcgencmd hdmi_timings 1920 1 58 183 183 256 1 5 4 12 0 0 0 56.737589 0 36839035.69 1
			## not better
			#vcgencmd hdmi_timings 1920 1 50 230 250 256 1 4 4 13 0 0 0 56.7 0 38479455 1
			## gut
			#vcgencmd hdmi_timings 1920 1 50 250 250 260 1 3 4 10 0 0 0 56.7 0 38793573 1
			##auch gut
			#vcgencmd hdmi_timings 1920 1 50 250 250 262 1 2 4 9 0 0 0 56.7 0 38793573 1
			### nu 1600er
			## best so far
			#vcgencmd hdmi_timings 1600 1 80 240 240 248 1 8 3 10 0 0 0 56.7 0 33296508 1
			## best 252 so far, 248 v-viewport
			vcgencmd hdmi_timings 1600 1 60 220 240 252 1 8 5 12 0 0 0 56.7 0 33296508 1
			## exakt test, oben als basis, aber ob das sheet script genau ist?
			#vcgencmd hdmi_timings 1600 1 60 220 240 252 1 8 5 12 0 0 0 56.737589 0 33318581.76 1
			tvservice -e "DMT 87"
			fbset -depth 8 && fbset -depth 16 -xres 1600 -yres 248
			# set the custom_viewport_width 
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for 240x248p@56.7hz timings" >&2		
			else
				echo -e "custom_viewport_width = \"1920\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1920 for 240x248p@56.7hz timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade 384x256 timings" >&2
		else
			#if [ "$rom_bn" == "rtype" ] || [ "$rom_bn" == "rtypew" ] || [ "$rom_bn" == "rtypeu" ] || [ "$rom_bn" == "rtypej" ]; then
		    ## r-type
			#vcgencmd hdmi_timings 1920 1 50 320 310 288 1 1 3 1 0 0 0 55 0 41900000 1
			###vcgencmd hdmi_timings 1920 1 56 176 176 268 1 6 8 8 0 0 0 55.0 0 37131600 1
			### ok soweit
			#vcgencmd hdmi_timings 1920 1 80 260 300 266 1 6 8 8 0 0 0 55.0 0 40550400 1
			## exact refresh
			#vcgencmd hdmi_timings 1920 1 120 192 358 256 1 8 5 18 0 0 0 55.017606 0 41054137.6 1
			#vcgencmd hdmi_timings 1920 1 152 247 280 240 1 3 7 12 0 0 0 60 0 40860000 1
			### real hori khz 15.625 khz
			#vcgencmd hdmi_timings 1920 1 120 192 368 256 1 8 6 14 0 0 0 55.017606 0 40625000.27 1
			vcgencmd hdmi_timings 1536 1 60 240 260 256 1 10 4 14 0 0 0 55 0 32739520 1
			tvservice -e "DMT 87"
			fbset -depth 8 && fbset -depth 16 -xres 1536 -yres 256
			# set the custom_viewport_width 
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for 384x256 timings" >&2		
			else
				echo -e "custom_viewport_width = \"1536\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1536 for 384x256 timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade 384x256 timings" >&2
		fi

	
	elif [ "$rom_resolution" == "256x240" ]; then

		if grep -w "$rom_bn" /opt/retropie/configs/all/dataeast256x240a5744.txt ; then
			###   NOT FINISHED
			## bad dudes, robocop, boulder dash an many more...
			#vcgencmd hdmi_timings 1920 1 34 229 307 240 1 5 8 23 0 0 0 57.4 0 39447576 1
			# based on sir ironics - super fluid - y fehlt etwas
			#vcgencmd hdmi_timings 1920 1 50 250 250 250 1 8 8 8 0 0 0 57.4 0 38847172 1
			# zu viel h hz, es zuckt wieder
			#vcgencmd hdmi_timings 1920 1 50 250 250 260 1 3 0 18 0 0 0 57.4 0 39839618 1
			# sehr gut
			#vcgencmd hdmi_timings 1920 1 50 250 250 260 1 3 5 5 0 0 0 57.4 0 38705394 1
			# cool nur m03+, aber etwa mehr lag. fba schneller
			#vcgencmd hdmi_timings 1920 1 50 250 250 240 1 9 6 18 0 0 0 57.444853 0 38735638.83 1
			# cool m03+, aber + hat etwas mehr lag (immer?)
			#vcgencmd hdmi_timings 1920 1 120 240 360 240 1 9 6 18 0 0 0 57.444853 0 41401654.45 1
			# khz fast exakt 1920 res
			#vcgencmd hdmi_timings 1920 1 50 250 250 250 1 7 5 10 0 0 0 57.4162 0 38574499.81 1
			## new 1600 res, use 1536 viewport - or 1536 super res...
			# first test with multiple of 256 - 1536 super res +exact timing:
			# fbneo still not fluid
			#vcgencmd hdmi_timings 1536 1 100 160 300 240 1 8 4 21 0 0 0 57.4 0 32844739 1
			## try 60hz
			vcgencmd hdmi_timings 1536 1 100 160 300 240 1 3 3 16 0 0 0 60 0 32949120 1
			## standard 60hz
			#vcgencmd hdmi_timings 1920 1 152 247 280 240 1 3 7 12 0 0 0 60 0 40860000 1
			tvservice -e "DMT 87"
			fbset -depth 8 && fbset -depth 16 -xres 1536 -yres 240
			# set the custom_viewport_width 
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for XXX x240 timings" >&2		
			else
				echo -e "custom_viewport_width = \"1536\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1536 for XXX x256 timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade XXX x256 timings" >&2
		else
			# end of custom_viewport_width
			echo "Running arcade XXX x256 timings" >&2
			## halley's comet
			### nes
			vcgencmd hdmi_timings 1536 1 100 160 300 240 1 3 3 16 0 0 0 60 0 32949120 1
			tvservice -e "DMT 87"
			fbset -depth 8 && fbset -depth 16 -xres 1536 -yres 240
			# set the custom_viewport_width 
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for $rom_resolution timings" >&2		
			else
				echo -e "custom_viewport_width = \"1536\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1536 for $rom_resolution timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade $rom_resolution timings" >&2	
		fi
	
	elif [ "$rom_resolution" == "320x240" ] || [ "$rom_resolution" == "640x480" ]; then
		if grep -w "$rom_bn" /opt/retropie/configs/all/twincobra.txt ; then
		  ## other 55hz games but with 240p !! + twin cobra
			## VSync  - 54.8766Hz
			## HSync  - 15.2822kHz ? really ?
			#vcgencmd hdmi_timings 1920 1 120 240 360 252 1 5 2 19 0 0 0 54.9 0 40292208 1
			#vcgencmd hdmi_timings 1920 1 120 240 360 256 1 3 0 19 0 0 0 54.9 0 40292208 1
			## exact
			#vcgencmd hdmi_timings 1920 1 120 240 360 240 1 14 10 22 0 0 0 54.877858 0 41434977.9 1
			## mit exakt hori khz
			#vcgencmd hdmi_timings 1920 1 120 240 360 240 1 11 10 18 0 0 0 54.877858 0 40420835.09 1
			vcgencmd hdmi_timings 1600 1 80 280 280 240 1 13 6 20 0 0 0 54.9 0 34310304 1
			tvservice -e "DMT 87"
			fbset -depth 8 && fbset -depth 16 -xres 1600 -yres 240
			# set the custom_viewport_width 
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for 320x240@55hz timings" >&2		
			else
				echo -e "custom_viewport_width = \"1600\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1600 for 320x240p@55hz timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade 320x240 timings" >&2
		 
		elif grep -w "$rom_bn" /opt/retropie/configs/all/toaplan155.txt ; then
			## rallybik, outzone, demonwld
			## 320x240@55.161545 Hz
			## toaplan1.cpp
			## toaplan1.cpp - 55hz games works smooth with fba, 57hz games not
			#vcgencmd hdmi_timings 1920 1 120 240 360 240 1 11 10 18 0 0 0 55.161545 0 40629787.59 1
			vcgencmd hdmi_timings 1600 1 100 160 300 240 1 12 7 25 0 0 0 55.2 0 33861888 1
			tvservice -e "DMT 87"
			fbset -depth 8 && fbset -depth 16 -xres 1600 -yres 240
			# set the custom_viewport_width 
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for 320x240@55hz timings" >&2		
			else
				echo -e "custom_viewport_width = \"1600\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1600 for 320x240p@55.2hz timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade 320x240 timings" >&2
			
		elif grep -w "$rom_bn" /opt/retropie/configs/all/toaplan157.txt ; then
			## vimana, truxton
			## 320x240@57.613169 Hz
			## toaplan1.cpp
			### fba
			#vcgencmd hdmi_timings 1920 1 112 247 320 240 1 3 7 12 0 0 0 60 0 40860000 1
			### mame2003+
			#vcgencmd hdmi_timings 1920 1 120 240 360 240 1 9 6 18 0 0 0 57.613169 0 41522963.16 1
			## truxtion bessr aber nicht gut mit 60hz?? alter fba driver?
			## bis fba 42 war mit 60hz fba perfekt
			#vcgencmd hdmi_timings 1920 1 112 247 320 240 1 3 7 12 0 0 0 60 0 40860000 1
			### mame2003+ & low real hori khz
			#vcgencmd hdmi_timings 1920 1 120 240 360 240 1 8 5 13 0 0 0 57.613169 0 40458271.8 1
			## nu timing script
			## toaplan1.cpp - 55hz games works smooth with fba, 57hz games not
			### !!!  as long as fba uses no newer driver for the 57hz part of the toaplan1.cpp driver games, we go with 60hz
			#vcgencmd hdmi_timings 1600 1 80 160 290 240 1 3 3 16 0 0 0 60 0 33483600 1
			vcgencmd hdmi_timings 1600 1 100 160 300 240 1 3 5 14 0 0 0 60 0 33955200 1
			## not complete fluid with fba / even fba neo 2.97.44 - why?
			#vcgencmd hdmi_timings 1600 1 100 160 300 240 1 9 5 20 0 0 0 57.6 0 34089984 1
			
			tvservice -e "DMT 87"
			fbset -depth 8 && fbset -depth 16 -xres 1600 -yres 240
			# set the custom_viewport_width 
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for 320x240@57.6hz timings" >&2		
			else
				echo -e "custom_viewport_width = \"1600\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1600 for 320x240p@57.6hz timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade 320x240 timings" >&2
		elif [[ "$rom_bn" == *raiden2* ]] || [[ "$rom_bn" == *raidendx* ]] || [[ "$rom_bn" == *z* ]]; then
			### VSync - 55.4859Hz  \
			### HSync - 15.5586kHz
			#vcgencmd hdmi_timings 1920 1 120 240 360 256 1 4 0 19 0 0 0 55.5 0 40879080 1
			# recht gut
			#vcgencmd hdmi_timings 1920 1 80 260 300 266 1 1 3 12 0 0 0 55.5 0 40066560 1
			# sehr gut v-size
			#vcgencmd hdmi_timings 1920 1 120 240 360 260 1 2 0 17 0 0 0 55.5 0 40879080 1
			# next try exakt, jochen
			#vcgencmd hdmi_timings 1920 1 120 240 360 240 1 14 10 20 0 0 0 55.407801 0 41542552.88 1 
			vcgencmd hdmi_timings 1600 1 100 160 300 240 1 13 6 23 0 0 0 55.4 0 33745248 1
			tvservice -e "DMT 87"
			fbset -depth 8 && fbset -depth 16 -xres 1600 -yres 240
			# set the custom_viewport_width 
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for 320x240@55hz timings" >&2		
			else
				echo -e "custom_viewport_width = \"1600\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1600 for 320x240p@55.4hz timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade 320x240 timings" >&2
		elif [[ "$rom_bn" == *r2dx_v33* ]]; then
			#vcgencmd hdmi_timings 1920 1 120 240 360 260 1 2 0 17 0 0 0 55.5 0 40879080 1
			#vcgencmd hdmi_timings 1920 1 120 240 360 260 1 2 0 17 0 0 0 55.47 0 41589187.2 1
			vcgencmd hdmi_timings 1600 1 100 160 300 240 1 11 6 26 0 0 0 55.5 0 33926040 1
			tvservice -e "DMT 87"
			fbset -depth 8 && fbset -depth 16 -xres 1600 -yres 240
			# set the custom_viewport_width 
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for 320x240@55hz timings" >&2		
			else
				echo -e "custom_viewport_width = \"1600\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1600 for 320x240p@55.5hz timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade 1920x240 timings" >&2
		
		elif grep -w "$rom_bn" /opt/retropie/configs/all/cave57.txt ; then
			### CAVE 1st Generation Hardware
			# 15.625khz / 57.550645 hz 
			# air gallet, esp ra.de., battle garegga,  ketsui, fixeight, dogyuun, batsugun ...
			# driver MCFG_SCREEN_REFRESH_RATE(15625/271.5) = 57.550645 hz
			# noch falsch
			#vcgencmd hdmi_timings 1920 1 120 240 360 260 1 0 0 11 0 0 0 57.6 0 41209344 1
			 ## m2003+ ok, could be better
			 #vcgencmd hdmi_timings 1920 1 50 250 250 250 1 2 2 17 0 0 0 57.6 0 38555712 1
			 ## fba - runs smooth only with 60hz
			 #vcgencmd hdmi_timings 1920 1 152 247 280 240 1 3 7 12 0 0 0 60 0 40860000 1
			 # m03+ sehr nice
			 # fba etwa schlechter
			 #vcgencmd hdmi_timings 1920 1 120 240 360 240 1 9 6 18 0 0 0 57.550645 0 41477900.86 1
			 ## 60hz 
			 #vcgencmd hdmi_timings 1920 1 112 247 320 240 1 3 7 12 0 0 0 60 0 40860000 1
			 vcgencmd hdmi_timings 1600 1 100 160 300 240 1 3 5 14 0 0 0 60 0 33955200 1
			 #vcgencmd hdmi_timings 1920 1 50 250 250 240 1 9 7 17 0 0 0 57.550645 0 38806975.43 1
			tvservice -e "DMT 87" > /dev/null
			fbset -depth 8 && fbset -depth 16 -xres 1600 -yres 240 > /dev/null
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for xxx timings" >&2		
			else
				echo -e "custom_viewport_width = \"1600\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1600 timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade 1600x240 timings" >&2
		elif grep -w "$rom_bn" /opt/retropie/configs/all/toaplan2.txt ; then
			### toaplan2.cpp game / kingdom grand prix
			## toaplan2.txt not yet created !!!!!! adb.arcadeitalia.net 
			vcgencmd hdmi_timings 1600 1 100 160 300 240 1 5 5 13 0 0 0 59.7 0 33914376 1
			 #vcgencmd hdmi_timings 1920 1 50 250 250 240 1 9 7 17 0 0 0 57.550645 0 38806975.43 1
			tvservice -e "DMT 87" > /dev/null
			fbset -depth 8 && fbset -depth 16 -xres 1600 -yres 240 > /dev/null
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for xxx timings" >&2		
			else
				echo -e "custom_viewport_width = \"1600\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1600 timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade 1600x240 timings" >&2
		else

			vcgencmd hdmi_timings 1600 1 100 160 300 240 1 2 5 15 0 0 0 60 0 33955200 1
			tvservice -e "DMT 87"
			fbset -depth 8 && fbset -depth 16 -xres 1600 -yres 240
			# set the custom_viewport_width 
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for $rom_resolution timings" >&2		
			else
				echo -e "custom_viewport_width = \"1600\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1600 for $rom_resolution timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade $rom_resolution timings" >&2
		fi
		
	# IGS PGM
	elif [ "$rom_resolution" == "448x224" ]; then
		if grep -w "$rom_bn" /opt/retropie/configs/all/pgm59.txt ; then
			
			# CAVE IGS PGM Hardware games 59.17hz
			# PGM, some cave games zb ESPGALUDA, ketsui
			#vcgencmd hdmi_timings 1920 1 102 288 330 240 1 3 9 12 0 0 0 59.2 0 41260032 1
			## new 
			vcgencmd hdmi_timings 1792 1 140 170 350 224 1 13 6 22 0 0 0 59.2 0 38466976 1
			tvservice -e "DMT 87"
			fbset -depth 8 && fbset -depth 16 -xres 1792 -yres 224
			# set the custom_viewport_width 
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for $rom_resolution timings" >&2		
			else
				echo -e "custom_viewport_width = \"1792\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1792 for $rom_resolution timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade $rom_resolution timings" >&2
		elif grep -w "$rom_bn" /opt/retropie/configs/all/pgm60.txt ; then
			# CAVE IGS PGM Hardware games 60hz 
			#vcgencmd hdmi_timings 1600 1 100 160 300 240 1 3 5 14 0 0 0 60 0 33955200 1
			## new
			vcgencmd hdmi_timings 1792 1 140 170 350 224 1 11 6 21 0 0 0 60 0 38545440 1
			tvservice -e "DMT 87" > /dev/null
			fbset -depth 8 && fbset -depth 16 -xres 1792 -yres 224 > /dev/null
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for xxx timings" >&2		
			else
				echo -e "custom_viewport_width = \"1792\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1792 timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade 1600x240 timings" >&2
		else

			vcgencmd hdmi_timings 1792 1 140 170 350 224 1 11 6 21 0 0 0 60 0 38545440 1
			### neo geo
			#vcgencmd hdmi_timings 1920 1 112 247 350 224 1 13 8 19 0 0 0 59.186 0 40610000 1
			tvservice -e "DMT 87"
			fbset -depth 8 && fbset -depth 16 -xres 1792 -yres 224
			# set the custom_viewport_width 
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for $rom_resolution timings" >&2		
			else
				echo -e "custom_viewport_width = \"1792\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1792 for $rom_resolution timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade $rom_resolution timings" >&2
		fi
		
	elif [ "$rom_resolution" == "320x224" ] || [ "$rom_resolution" == "304x224" ]; then
		## my finding
		vcgencmd hdmi_timings 1600 1 100 160 300 240 1 3 5 14 0 0 0 60 0 33955200 1
		##vcgencmd hdmi_timings 1920 1 122 247 310 240 2 1 6 14 0 0 0 60 0 40860000 1
		tvservice -e "DMT 87"
		fbset -depth 8 && fbset -depth 16 -xres 1600 -yres 224
		# set the custom_viewport_width 
		if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
			echo "Existing custom_viewport_width for $rom_resolution timings" >&2		
		else
			echo -e "custom_viewport_width = \"1600\"" >> "$rom_fp"".cfg"
			echo "Setting custom_viewport_width=1600 for $rom_resolution timings" >&2
		fi
		# end of custom_viewport_width
		echo "Running arcade $rom_resolution timings" >&2
	
	elif [ "$rom_resolution" == "336x240" ]; then
		## atari system 1
		#vcgencmd hdmi_timings 1920 1 122 247 310 240 1 3 7 12 0 0 0 60 0 40860000 1
		#vcgencmd hdmi_timings 1680 1 120 160 320 240 1 3 5 14 0 0 0 59.9 0 35781884 1
		vcgencmd hdmi_timings 1680 1 110 160 310 240 1 3 5 14 0 0 0 59.9 0 35467988 1
		tvservice -e "DMT 87"
		fbset -depth 8 && fbset -depth 16 -xres 1680 -yres 240
		# set the custom_viewport_width 
		if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
			echo "Existing custom_viewport_width for $rom_resolution timings" >&2		
		else
			echo -e "custom_viewport_width = \"1680\"" >> "$rom_fp"".cfg"
			echo "Setting custom_viewport_width=1680 for $rom_resolution timings" >&2
		fi
		# end of custom_viewport_width
		echo "Running arcade $rom_resolution timings" >&2
	elif [ "$rom_resolution" == "256x224" ] || [ "$rom_resolution" == "768x224" ] || [ "$rom_resolution" == "256x192" ]; then
		if [[ "$rom_bn" == *bublbobl* ]] || [[ "$rom_bn" == *boblbobl* ]]; then
			### bubble bobble atm 60hz
			vcgencmd hdmi_timings 1664 1 100 150 300 224 1 12 4 22 0 0 0 60 0 34804080 1
			tvservice -e "DMT 87"
			fbset -depth 8 && fbset -depth 16 -xres 1536 -yres 224
			# set the custom_viewport_width 
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for $rom_resolution timings" >&2		
			else
				echo -e "custom_viewport_width = \"1536\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1536 for $rom_resolution timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade $rom_resolution timings" >&2
		elif [[ "$rom_bn" == *raiden* ]] || [[ "$rom_bn" == *gng* ]]; then
			### raiden
			vcgencmd hdmi_timings 1664 1 100 160 300 224 1 11 5 23 0 0 0 59.6 0 34860755 1
			tvservice -e "DMT 87"
			fbset -depth 8 && fbset -depth 16 -xres 1536 -yres 224
			# set the custom_viewport_width 
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for $rom_resolution timings" >&2		
			else
				echo -e "custom_viewport_width = \"1536\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1536 for $rom_resolution timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade $rom_resolution timings" >&2
		elif [[ "$rom_bn" == *argus* || "$rom_bn" == *valtric* || "$rom_bn" == *butasan* ]] ; then
			  ## raiden
			#vcgencmd hdmi_timings 1920 1 50 250 250 250 1 8 10 8 0 0 0 57 0 38858040 1
			#vcgencmd hdmi_timings 1920 1 120 240 360 240 1 14 10 10 0 0 0 54 0 40772160 1
			### on the edge
			vcgencmd hdmi_timings 1664 1 80 150 260 224 1 22 14 28 0 0 0 54 0 33499008 1
			
			tvservice -e "DMT 87"
			fbset -depth 8 && fbset -depth 16 -xres 1536 -yres 224
			# set the custom_viewport_width 
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for XXX x240 timings" >&2		
			else
				echo -e "custom_viewport_width = \"1536\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1536 for XXX x224 timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade XXX x256 timings" >&2
		elif grep -w "$rom_bn" /opt/retropie/configs/all/nmk16.txt ; then
			### nmk16
			#vcgencmd hdmi_timings 1920 1 50 250 250 250 1 8 10 8 0 0 0 57 0 38858040 1
			#vcgencmd hdmi_timings 1920 1 112 247 320 240 1 8 7 20 0 0 0 57 0 40739325 1
			vcgencmd hdmi_timings 1536 1 100 160 300 224 1 19 10 26 0 0 0 56.2 0 32864861 1
			tvservice -e "DMT 87"
			fbset -depth 8 && fbset -depth 16 -xres 1536 -yres 224
			# set the custom_viewport_width 
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for XXX x240 timings" >&2		
			else
				echo -e "custom_viewport_width = \"1536\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1536 for XXX x256 timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade XXX x256 timings" >&2
		else
			### set viewport to 1536 width or test integer scale
			## e.g. bomb jack / 60hz
			vcgencmd hdmi_timings 1664 1 100 150 300 224 1 12 4 22 0 0 0 60 0 34804080 1
			tvservice -e "DMT 87"
			fbset -depth 8 && fbset -depth 16 -xres 1536 -yres 224
			# set the custom_viewport_width 
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for $rom_resolution timings" >&2		
			else
				echo -e "custom_viewport_width = \"1536\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1536 for $rom_resolution timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade $rom_resolution timings" >&2
		fi
	elif [ "$rom_resolution" == "384x224" ]; then
		
		if grep -w "$rom_bn" /opt/retropie/configs/all/nmk16.txt ; then
			### nmk16
			#vcgencmd hdmi_timings 1920 1 50 250 250 250 1 8 10 8 0 0 0 57 0 38858040 1
			#vcgencmd hdmi_timings 1920 1 112 247 320 240 1 8 7 20 0 0 0 57 0 40739325 1
			vcgencmd hdmi_timings 1536 1 100 160 300 224 1 19 10 26 0 0 0 56.2 0 32864861 1
			tvservice -e "DMT 87"
			fbset -depth 8 && fbset -depth 16 -xres 1536 -yres 224
			# set the custom_viewport_width 
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for XXX x240 timings" >&2		
			else
				echo -e "custom_viewport_width = \"1536\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1536 for XXX x256 timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade XXX x256 timings" >&2
		
	
		elif grep -w "$rom_bn" /opt/retropie/configs/all/cps123.txt ; then
		  ### cps1
			### 1920
			#vcgencmd hdmi_timings 1920 1 102 247 330 224 1 11 8 21 0 0 0 59.637405 0 40919370.52 1
			### 1536
			#vcgencmd hdmi_timings 1536 1 110 160 310 224 1 12 5 22 0 0 0 59.6 0 33167877 1
			vcgencmd hdmi_timings 1536 1 100 160 300 224 1 13 5 20 0 0 0 59.637 0 32749777 1
			tvservice -e "DMT 87"
			fbset -depth 8 && fbset -depth 16 -xres 1536 -yres 224
			# set the custom_viewport_width 
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for $rom_resolution timings" >&2		
			else
				echo -e "custom_viewport_width = \"1536\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1536 for $rom_resolution timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade $rom_resolution timings" >&2
		
		else
			## black tiger, rygar, standard
			### snes timing
			### new lowest possible res - all standard 256x224, 383x224, cps1/2
			#vcgencmd hdmi_timings 1920 1 112 247 320 240 1 3 7 12 0 0 0 60 0 40860000 1
			#vcgencmd hdmi_timings 1536 1 80 150 260 224 1 9 7 22 0 0 0 60 0 31848720 1
			vcgencmd hdmi_timings 1536 1 120 160 300 224 1 11 5 22 0 0 0 60 0 33263520 1
			tvservice -e "DMT 87"
			fbset -depth 8 && fbset -depth 16 -xres 1536 -yres 224
			# set the custom_viewport_width 
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for $rom_resolution timings" >&2		
			else
				echo -e "custom_viewport_width = \"1536\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1536 for $rom_resolution timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade $rom_resolution timings" >&2	
		fi
	elif [ "$rom_resolution" == "400x254" ]; then
		## MK  time NOT FINISHED
		#vcgencmd hdmi_timings 1920 1 50 320 310 288 1 1 3 1 0 0 0 55 0 41900000 1
		###vcgencmd hdmi_timings 1920 1 56 176 176 268 1 6 8 8 0 0 0 55.0 0 37131600 1
		### ok soweit
		#vcgencmd hdmi_timings 1920 1 80 260 300 266 1 6 8 8 0 0 0 55.0 0 40550400 1
		#vcgencmd hdmi_timings 1920 1 90 240 300 256 1 7 8 15 0 0 0 55.0 0 40111500 1
		## exact try
		#vcgencmd hdmi_timings 1920 1 122 247 310 254 1 7 6 12 0 0 0 54.70684 0 39669078.53 1
		
		vcgencmd hdmi_timings 1600 1 100 150 300 254 1 9 4 19 0 0 0 54.7 0 33635030 1
		tvservice -e "DMT 87"
		fbset -depth 8 && fbset -depth 16 -xres 1600 -yres 254
		# set the custom_viewport_width 
		if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
			echo "Existing custom_viewport_width for 384x256 timings" >&2		
		else
			echo -e "custom_viewport_width = \"1600\"" >> "$rom_fp"".cfg"
			echo "Setting custom_viewport_width=1600 for 400x254 timings" >&2
		fi
		# end of custom_viewport_width
		echo "Running arcade 384x256 timings" >&2
	## namco sys 1
	elif [ "$rom_resolution" == "288x224" ] || [ "$rom_resolution" == "280x224" ]; then
	    ###  time NOT FINISHED
		if grep -w "$rom_bn" /opt/retropie/configs/all/288x224-60.6.txt ; then
		    ## namco old and some others
			#if [ "$rom_bn" == "galaga88" ] || [ "$rom_bn" == "dspirit"]; then
			#vcgencmd hdmi_timings 1920 1 110 240 340 224 1 9 2 28 0 0 0 60.6 0 41438280 1
			#vcgencmd hdmi_timings 1920 1 110 176 330 240 1 6 8 8 0 0 0 60.6 0 40264579 1
			# sir ironic standard 224p 60hz
			## + + + + vcgencmd hdmi_timings 1920 1 122 247 310 224 1 8 7 23 0 0 0 60 0 40860000 1
			## timings script
			#vcgencmd hdmi_timings 1920 1 152 247 280 224 1 8 7 23 0 0 0 60 0 40856280 1
			##
			#vcgencmd hdmi_timings 1920 1 112 247 320 224 1 8 5 23 0 0 0 60.6 0 40949844 1
			#vcgencmd hdmi_timings 1920 1 98 192 190 224 1 10 8 18 0 0 0 60.606061 0 37818182.06 1
			## not better
			#vcgencmd hdmi_timings 1512 1 90 140 270 224 1 9 5 21 0 0 0 60.6 0 31579145 1
			## 60hz is enought
			vcgencmd hdmi_timings 1512 1 100 160 280 224 1 12 5 21 0 0 0 60 0 32257440 1
			## nu 1728
			#vcgencmd hdmi_timings 288 1 36 37 42 224 1 13 6 19 0 0 0 6400000 1
			tvservice -e "DMT 87" > /dev/null
			fbset -depth 8 && fbset -depth 16 -xres 1440 -yres 224 > /dev/null
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for xxx timings" >&2		
			else
				echo -e "custom_viewport_width = \"1440\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1440 timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade 288x224 or 280x224 timings" >&2
	    else 
			vcgencmd hdmi_timings 1512 1 100 160 280 224 1 12 5 21 0 0 0 60 0 32257440 1
			#vcgencmd hdmi_timings 288 1 36 37 42 224 1 13 6 19 0 0 60.61 0 6400000 1 
			tvservice -e "DMT 87"
			fbset -depth 8 && fbset -depth 16 -xres 1440 -yres 224
			# set the custom_viewport_width 
			if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
				echo "Existing custom_viewport_width for $rom_resolution timings" >&2		
			else
				echo -e "custom_viewport_width = \"1440\"" >> "$rom_fp"".cfg"
				echo "Setting custom_viewport_width=1440  for $rom_resolution timings" >&2
			fi
			# end of custom_viewport_width
			echo "Running arcade $rom_resolution timings" >&2
		fi
	
	elif [ "$rom_resolution" == "256x232" ]; then
	  ## crystal castles + i,robot and some puzzle games
		## 
		#vcgencmd hdmi_timings 1920 1 50 250 250 250 1 8 10 8 0 0 0 58.97 0 38750000 1
		### 
		#vcgencmd hdmi_timings 1920 1 122 247 310 240 1 2 4 16 0 0 0 60 0 40856280 1
		vcgencmd hdmi_timings 1664 1 90 150 280 232 1 7 5 18 0 0 0 60 0 34332480 1
		tvservice -e "DMT 87"
		fbset -depth 8 && fbset -depth 16 -xres 1664 -yres 232
		# set the custom_viewport_width 
		if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
			echo "Existing custom_viewport_width for 256x232@60hz timings" >&2		
		else
			echo -e "custom_viewport_width = \"1664\"" >> "$rom_fp"".cfg"
			echo "Setting custom_viewport_width=1664 for 256x232p@55hz timings" >&2
		fi
		# end of custom_viewport_width
		echo "Running arcade 256x232 timings" >&2
	elif [ "$rom_resolution" == "240x240" ]; then
	  ## burger time and many others
		## 
		#vcgencmd hdmi_timings 1920 1 50 250 250 250 1 8 10 8 0 0 0 58.97 0 38750000 1
		### 
		## many no scrolling 57.4hz games
		#vcgencmd hdmi_timings 1680 1 100 160 300 240 1 8 5 20 0 0 0 57.4 0 35101248 1
		## but renegade is 60hz, so...
		## use 1440 viewport
		#vcgencmd hdmi_timings 1680 1 100 160 300 240 1 4 3 15 0 0 0 60 0 35212800 1
		## more vertical, use 1440 viewport
		vcgencmd hdmi_timings 1560 1 100 160 300 240 1 4 3 15 0 0 0 60 0 33326400 1
		
		tvservice -e "DMT 87"
		fbset -depth 8 && fbset -depth 16 -xres 1560 -yres 240
		# set the custom_viewport_width 
		if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
			echo "Existing custom_viewport_width for 240x240p@60hz timings" >&2		
		else
			echo -e "custom_viewport_width = \"1440\"" >> "$rom_fp"".cfg"
			echo -e "custom_viewport_x = \"60\"" >> "$rom_fp"".cfg"
			echo "Setting custom_viewport_width=1440 for 240x240p@60hz timings" >&2
		fi
		# end of custom_viewport_width
		echo "Running arcade 240x240 timings" >&2
	elif [ "$rom_resolution" == "384x240" ]; then
		#vcgencmd hdmi_timings 1536 1 120 160 300 240 1 8 5 20 0 0 0 57.4 0 33158143 1
		## 60hz works fine for 57hz games, cause there are 60hz games too
		vcgencmd hdmi_timings 1536 1 100 160 300 240 1 3 5 14 0 0 0 60 0 32949120 1
		tvservice -e "DMT 87"
		fbset -depth 8 && fbset -depth 16 -xres 1536 -yres 240
		# set the custom_viewport_width 
		if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
			echo "Existing custom_viewport_width for 384x240@60hz timings" >&2		
		else
			echo -e "custom_viewport_width = \"1536\"" >> "$rom_fp"".cfg"
			echo "Setting custom_viewport_width=1536 for 320x240p@60z timings" >&2
		fi
		# end of custom_viewport_width
		echo "Running arcade 384x240@60hz timings" >&2
	else
		
		# 240p 60hz sir ironic
		#vcgencmd hdmi_timings 1920 1 112 247 320 240 1 3 7 12 0 0 0 60 0 40860000 1
		# genauer
		#vcgencmd hdmi_timings 1920 1 112 247 320 240 1 3 7 12 0 0 0 60 0 40856280 1
		
		### sir ironic SNES
		#vcgencmd hdmi_timings 1920 1 128 200 316 240 1 1 8 13 0 0 0 60.10 0 40380000 1
		### sir ironic
		##vcgencmd hdmi_timings 1920 1 122 247 310 224 1 8 7 23 0 0 0 60 0 40860000 1	   
		### pce
		#vcgencmd hdmi_timings 1920 1 112 247 350 240 1 1 7 14 0 0 0 60 0 40860000 1
		### despite 384x240@57.6hz
		vcgencmd hdmi_timings 1536 1 100 160 300 240 1 3 5 14 0 0 0 60 0 32949120 1
		tvservice -e "DMT 87"
		fbset -depth 8 && fbset -depth 16 -xres 1536 -yres 240
		#echo "Running else timings" >&2
		if grep "custom_viewport_width" "$rom_fp"".cfg"; then 
			echo "Existing custom_viewport_width for 384x240@57.6/60hz timings" >&2		
		else
			echo -e "custom_viewport_width = \"1536\"" >> "$rom_fp"".cfg"
			echo "Setting custom_viewport_width=1536 for 384x240p@57.6/60hz timings" >&2
		fi
		# end of custom_viewport_width
		echo "Running arcade 384x240 timings" >&2
	fi
		
else
    vcgencmd hdmi_timings 320 1 16 30 34 240 1 2 3 22 0 0 0 60 0 6400000 1  > /dev/null
	tvservice -e "DMT 87" > /dev/null
	fbset -depth 8 && fbset -depth 16 -xres 320 -yres 240 > /dev/null
fi
