#!/bin/bash

###################################################################
# Script Name	: On-screen graphic finder | onscreen-graphic-finder.sh
# Description	: Finds the location of an element in a GUI interface whatever the screen resolution and wherever this element is located.
#				  The script takes a full screenshot, which helps locate the item you want.
#				  It is sometimes necessary to add the parameters x and y of the command to move the automatic click of the mouse which allows to interact with the element or therefore to select it.
#				  The script can be modified to use interfaces other than GNOME and other screenshots software.
#				  Example command: `./auto-click-screenreader.sh allow_button 50 30`
#				  Sources : https://blog.sleeplessbeastie.eu/2013/01/21/how-to-automate-mouse-and-keyboard/
# Args          : 
# Parameters	: $1 : name of the object to find (name of the file without extension); $2 : mouse shift in x; $3 : mouse shift in y
# Author	   	: Régis "Sioxox" André
# Email	    	: pro@regisandre.be
# Website		: https://regisandre.be
# Github		: https://github.com/regisandre
###################################################################

RED='\033[1;31m'
GREEN="\033[1;32m"
NC='\033[0m' # No Color

# Check if all the need packages and scripts are installed
checkNecessaryPackagesInstalled() {
    # Packages needed : xdotool, xautomation, gnome-screenshot, coreutils, sed, grep, zenity, zenity-common
    packagesNeeded=(xdotool xautomation gnome-screenshot coreutils sed grep zenity zenity-common)
    
    # Checks one by one if the packages are installed and adds them to an installation list
    for pn in ${packagesNeeded[@]}; do
        if [[ $(dpkg -s $pn | grep Status) != *"installed"* ]]; then
            echo -e "${RED}$pn is not installed${NC}"
            packagesThatMustBeInstalled+="$pn "
        fi
    done

    # Automatically install required packages and scripts
    if [[ ! -z "$packagesThatMustBeInstalled" ]]; then
        # Multi-step question for packages installation with zenity (GUI) or simple questions in the terminal
        if [[ $(dpkg -s zenity | grep Status) == *"installed"* ]]; then # Check if zenity is installed
            if zenity --question --title="Confirm automatic installation" --text="Are you sure you want to go ahead and install these programs: $packagesThatMustBeInstalled?" --no-wrap 
            then
                sudo apt update && sudo apt install -y $packagesThatMustBeInstalled
            else
                if zenity --question --title="Packages needed" --text="These packages must be installed for the script to work.\n\nDo you want to retry installing the packages necessary for this script to run correctly?" --no-wrap
                then
                    checkNecessaryPackagesInstalled # Restart the required package checks
                else
                    if ! zenity --question --title="Continue without all packages installed?" --text="Do you want to continue without all the packages being installed? This could cause problems during script execution." --no-wrap
                    then
                        exit 1
                    fi
                fi
            fi  
        else
            echo -n "Are you sure you want to go ahead and install these programs: $packagesThatMustBeInstalled? (Y/n): "; read answer
            if [ "$answer" != "${answer#[Yy]}" ]; then
                sudo apt update && sudo apt install -y $packagesThatMustBeInstalled
            else
                echo -ne "\n${RED}These packages must be installed for the script to work${NC}\n\nDo you want to retry installing the packages necessary for this script to run correctly? (Y/n): "; read answer
                if [ "$answer" != "${answer#[Yy]}" ]; then
                    checkNecessaryPackagesInstalled # Restart the required package checks
                else
                    echo -n "Do you want to continue without all the packages being installed? This could cause problems during script execution (Y/n): "; read answer
                    if [ "$answer" == "${answer#[Yy]}" ]; then
                        exit 1
                    fi
                fi
            fi
        fi
    fi
}

# Check if there is Internet connection
checkInternetConnection() {
    if ping -q -c 1 -W 1 8.8.8.8 > /dev/null; then
        echo -ne "\n${GREEN}Internet connection : OK${NC}\n\n"
        checkNecessaryPackagesInstalled # Check if all the need packages and scripts are installed
    else
        # Multi-step question for the Internet connection with zenity (GUI) or simple questions in the terminal
        if [[ $(dpkg -s zenity | grep Status) == *"installed"* ]]; then # Check if zenity is installed
            if zenity --question --title="Internet problem" --text="First, connect the computer to the Internet to install any missing packages\n\nDo you want to try again after connecting to the Internet?" --no-wrap
            then
                checkInternetConnection # Restart the Internet connection test
            else
                if ! zenity --question --title="Continue without Internet?" --text="Do you want to continue without an Internet connection? This could cause problems during script execution." --no-wrap
                then
                    exit 1
                fi
            fi
        else
            echo -ne "${RED}First, connect the computer to the Internet${NC}\n\n"

            echo -n "Do you want to try again after connecting to the Internet? (Y/n): "; read answer
            if [ "$answer" != "${answer#[Yy]}" ]; then
                checkInternetConnection # Restart the Internet connection test
            else
                echo -n "Do you want to continue without an Internet connection? This could cause problems during script execution (Y/n): "; read answer
                if [ "$answer" == "${answer#[Yy]}" ]; then
                    exit 1
                fi
            fi
        fi
    fi
}

checkInternetConnection

# PAT file
# To make a PAT file, you need to screen shot the an image in PNG and convert it in PAT file
# png2pat filename.png > filename.pat
pat_file="./images/$1.pat"

# create temporary file to store screen shot
fullscreen_png_file="./images/fullscreen.png"

# create screen shot
gnome-screenshot --file="$fullscreen_png_file" &
#flameshot full -p "$fullscreen_png_file"
#shutter -f -o $fullscreen_png_file -e

sleep 1

# convert screen shot
#$tmp_file = convert $temporary

# search for a pattern
rpos=`visgrep $fullscreen_png_file $pat_file $pat_file`
#echo $rpos

if [ -n "$rpos" ]; then
  x=`echo $rpos | sed "s/\(.*\),.*/\1/"`
  x=`expr $x + $2`

  y=`echo $rpos | grep -Po "(?<=\d,)\d+"`
  #y=`echo '1234,350 -1' | awk 'BEGIN { FS=",|| " } { print $2 }'`
  y=`expr $y + $3`

  #echo -n "X = $x\nY = $y"

  xdotool mousemove $x $y
  xdotool click 1
fi

rm $fullscreen_png_file