#!/bin/bash

export TEXTDOMAIN=petget___pkg_chooser.sh
export OUTPUT_CHARSET=UTF-8

[ "`whoami`" != "root" ] && exec sudo -A ${0} ${@} #110505

if [ -f /root/.packages/download_path ]; then
 . /root/.packages/download_path
fi

clean_up () {
 if [ "$(ls /tmp/*_pet{,s}_quietly /tmp/install_classic 2>/dev/null |wc -l)" -eq 1 ]; then
  for MODE in $(ls /tmp/*_pet{,s}_quietly /tmp/install_classic)
  do
   mv $MODE $MODE.bak
  done
 fi
 mv /tmp/install_quietly /tmp/install_quietly.bak
 echo -n > /tmp/pkgs_to_install
 rm -f /tmp/{install,remove}{,_pets}_quietly 2>/dev/null
 rm -f /tmp/install_classic 2>/dev/null
 rm -f /tmp/download_pets_quietly 2>/dev/null
 rm -f /tmp/download_only_pet_quietly 2>/dev/null
 rm -f /tmp/pkgs_left_to_install 2>/dev/null
 rm -f /tmp/pkgs_to_install_done 2>/dev/null
 rm -f /tmp/overall_pkg_size* 2>/dev/null
 rm -f /tmp/overall_dependencies 2>/dev/null
 rm -f /tmp/mode_changed 2>/dev/null
 rm -f /tmp/force*_install 2>/dev/null
 rm -f /tmp/pkgs_to_install_done 2>/dev/null
 rm -f /tmp/pgks_really_installed 2>/dev/null
 rm -f /tmp/pgks_failed_to_install 2>/dev/null
 rm -f /tmp/overall_petget_missingpkgs_patterns.txt 2>/dev/null
 rm -f /tmp/overall_missing_libs.txt 2>/dev/null
 rm -f /tmp/overall_install_deport 2>/dev/null
 rm -f /tmp/pkgs_to_install_bar 2>/dev/null
 rm -f /tmp/manual_pkg_download 2>/dev/null
 rm -f /tmp/ppm_reporting 2>/dev/null
 rm -f /tmp/pkgs_DL_BAD_LIST 2>/dev/null
 rm -rf /tmp/PPM_LOGs/ 2>/dev/null
 mv $MODE.bak $MODE
 mv /tmp/install_quietly.bak /tmp/install_quietly
}
export -f clean_up

report_results () {
 # Info source files
 touch /tmp/ppm_reporting # progress bar flag
 /usr/local/petget/finduserinstalledpkgs.sh #make sure...
 sync
 rm -f /tmp/pgks_really_installed 2>/dev/null
 rm -f /tmp/pgks_failed_to_install 2>/dev/null
 for LINE in $(cat /tmp/pkgs_to_install_done  | cut -f 1 -d '|' | sort | uniq)
 do
  if [ -f /tmp/download_pets_quietly -o -f /tmp/download_only_pet_quietly \
   -o -f /tmp/manual_pkg_download ];then
   if [ -f /root/.packages/download_path ];then
    . /root/.packages/download_path
    DOWN_PATH="$DL_PATH"
   else
    DOWN_PATH=$HOME
   fi
   PREVINST=''
   REALLY=$(ls "$DOWN_PATH" | grep $LINE)
   [ "$REALLY" -a "$(grep $LINE /tmp/pkgs_DL_BAD_LIST 2>/dev/null | sort | uniq )" != "" ] && \
    REALLY='' && PREVINST="$(gettext 'was previously downloaded')"
  else
   PREVINST=''
   REALLY=$(grep $LINE /tmp/petget/installedpkgs.results)
   [ "$(grep $LINE /tmp/pgks_failed_to_install_forced 2>/dev/null | sort | uniq )" != "" -o \
    "$(grep $LINE /tmp/pkgs_DL_BAD_LIST 2>/dev/null | sort | uniq )" != "" ] \
    && REALLY='' && PREVINST="$(gettext 'was already installed')"
  fi
  if [ "$REALLY" != "" ]; then
   echo $LINE >> /tmp/pgks_really_installed
  else
   echo $LINE $PREVINST >> /tmp/pgks_failed_to_install
  fi
 done
 rm -f /tmp/pgks_failed_to_install_forced

 [ -f /tmp/pgks_really_installed ] && INSTALLED_PGKS="$(</tmp/pgks_really_installed)" \
  || INSTALLED_PGKS=''
 [ -f /tmp/pgks_failed_to_install ] && FAILED_TO_INSTALL="$(</tmp/pgks_failed_to_install)" \
  || FAILED_TO_INSTALL=''
 #MISSING_PKGS=$(cat /tmp/overall_petget_missingpkgs_patterns.txt |sort|uniq )
 MISSING_LIBS=$(cat /tmp/overall_missing_libs.txt 2>/dev/null | tr ' ' '\n' | sort | uniq )
 NOT_IN_PATH_LIBS=$(cat /tmp/overall_missing_libs_hidden.txt 2>/dev/null | tr ' ' '\n' | sort | uniq )
 cat << EOF > /tmp/overall_install_deport
Packages succesfully Installed or Downloaded 
$INSTALLED_PGKS

Packages that failed to be Installed or Downloaded, or were aborted be the user
$FAILED_TO_INSTALL

Missing Shared Libraries
$MISSING_LIBS

Existing Libraries that may be in a location other than /lib and /usr/lib
$NOT_IN_PATH_LIBS
EOF

 # Info window/dialogue (display and option to save "missing" info)
 MISSINGMSG1="<i><b>$(gettext 'No missing shared libraries')</b></i>"
 if [ "$MISSING_LIBS" ];then
  MISSINGMSG1="<i><b>$(gettext 'These libraries are missing:')
${MISSING_LIBS}</b></i>"
 fi
 if [ "$NOT_IN_PATH_LIBS" ];then #100830
  MISSINGMSG1="<i><b>${MISSINGMSG1}</b></i>
 
$(gettext 'These needed libraries exist but are not in the library search path (it is assumed that a startup script in the package makes these libraries loadable by the application):')
<i><b>${NOT_IN_PATH_LIBS}</b></i>"
 fi

 export REPORT_DIALOG='
 <window title="'$(gettext 'Puppy Package Manager')'" icon-name="gtk-about" default_height="550">
 <vbox>
  '"`/usr/lib/gtkdialog/xml_info fixed package_add.svg 60 " " "$(gettext "Package install/download report")"`"'
  <hbox space-expand="true" space-fill="true">
    <hbox scrollable="true" hscrollbar-policy="2" vscrollbar-policy="2" space-expand="true" space-fill="true">
      <hbox space-expand="false" space-fill="false">
        <eventbox name="bg_report" space-expand="true" space-fill="true">
          <vbox margin="5" hscrollbar-policy="2" vscrollbar-policy="2" space-expand="true" space-fill="true">
            '"`/usr/lib/gtkdialog/xml_pixmap dialog-complete.svg 32`"'
            <text angle="90" wrap="false" yalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"<big><b><span color='"'#15BC15'"'>'$(gettext 'Success')'</span></b></big> "</label></text>
          </vbox>
        </eventbox>
      </hbox>
      <vbox scrollable="true" shadow-type="0" hscrollbar-policy="2" vscrollbar-policy="1" space-expand="true" space-fill="true">
        <text ypad="5" xpad="5" yalign="0" xalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"<i><b>'${INSTALLED_PGKS}' </b></i>"</label></text>
      </vbox>
    </hbox>
  </hbox>

  <hbox space-expand="true" space-fill="true">
    <hbox scrollable="true" hscrollbar-policy="2" vscrollbar-policy="2" space-expand="true" space-fill="true">
      <hbox space-expand="false" space-fill="false">
        <eventbox name="bg_report" space-expand="true" space-fill="true">
          <vbox margin="5" hscrollbar-policy="2" vscrollbar-policy="2" space-expand="true" space-fill="true">
            '"`/usr/lib/gtkdialog/xml_pixmap dialog-error.svg 32`"'
            <text angle="90" wrap="false" yalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"<big><b><span color='"'#DB1B1B'"'>'$(gettext 'Failed')'</span></b></big> "</label></text>
          </vbox>
        </eventbox>
      </hbox>
      <vbox scrollable="true" shadow-type="0" hscrollbar-policy="2" vscrollbar-policy="1" space-expand="true" space-fill="true">
        <text ypad="5" xpad="5" yalign="0" xalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"<i><b>'${FAILED_TO_INSTALL}' </b></i>"</label></text>
      </vbox>
    </hbox>
  </hbox>

  <hbox space-expand="true" space-fill="true">
    <hbox scrollable="true" hscrollbar-policy="2" vscrollbar-policy="2" space-expand="true" space-fill="true">
      <hbox space-expand="false" space-fill="false">
        <eventbox name="bg_report" space-expand="true" space-fill="true">
          <vbox margin="5" hscrollbar-policy="2" vscrollbar-policy="2" space-expand="true" space-fill="true">
            '"`/usr/lib/gtkdialog/xml_pixmap building_block.svg 32`"'
            <text angle="90" wrap="false" yalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"<big><b><span color='"'#bbb'"'>'$(gettext 'Libs')'</span></b></big> "</label></text>
          </vbox>
        </eventbox>
      </hbox>
      <vbox scrollable="true" shadow-type="0" hscrollbar-policy="1" vscrollbar-policy="1" space-expand="true" space-fill="true">
        <text ypad="5" xpad="5" yalign="0" xalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"'${MISSINGMSG1}'"</label></text>
      </vbox>
    </hbox>
  </hbox>

  <hbox space-expand="false" space-fill="false">
    <button>
      <label>'$(gettext 'View details')'</label>
      '"`/usr/lib/gtkdialog/xml_button-icon document_viewer`"'
      <action>defaulttextviewer /tmp/overall_install_deport &</action>
     </button>
     <button ok></button>
     '"`/usr/lib/gtkdialog/xml_scalegrip`"'
  </hbox>
 </vbox>
 </window>'
 RETPARAMS="`gtkdialog --center -p REPORT_DIALOG`"
 echo 100 > /tmp/petget/install_status_percent
}
export -f report_results

check_total_size () {
 rm -f /tmp/petget_deps_visualtreelog 2>/dev/null
 rm -f /tmp/petget_frame_cnt 2>/dev/null
 rm -f /tmp/petget_missingpkgs_patterns{2,_acc,_acc0,_acc-prev,x0,_and_versioning_level1} 2>/dev/null
 rm -f /tmp/petget_moreframes 2>/dev/null
 rm -f /tmp/petget_tabs 2>/dev/null
 rm -f /tmp/pkgs_to_install_bar 2>/dev/null
 #required size
 NEEDEDK_PLUS=$( expr $(awk '{ sum += $1 } END { print sum }' /tmp/overall_pkg_size)) 
 [ -f /tmp/overall_pkg_size_RMV ] && \
  NEEDEDK_MINUS=$( expr $(awk '{ sum += $1 } END { print sum }' /tmp/overall_pkg_size_RMV)) \
  || NEEDEDK_MINUS=0
 [ ! "$NEEDEDK_MINUS" ] && NEEDEDK_MINUS=0
 NEEDEDK=$( expr $( expr $NEEDEDK_PLUS + $NEEDEDK_MINUS ) / 768 ) # 1.5x
 ACTION_MSG=$(gettext 'This is not enough space to download and install the packages (including dependencies) you have selected.')
 if [ -f /tmp/download_pets_quietly -o -f /tmp/download_only_pet_quietly ]; then
  NEEDEDK=$( expr $NEEDEDK / 3 ) # 0.5x
  [ "$DL_PATH" ] && DOWN_PATH="$DL_PATH" || DOWN_PATH="/root"
  ACTION_MSG="$(gettext 'This is not enough space to download the packages (including dependencies) you have selected in ')${DOWN_PATH}."
 fi
 if [ "$(cat /var/local/petget/nd_category 2>/dev/null)" = "true" ]; then
  NEEDEDKDOWN=$( expr $NEEDEDK / 3 )
 else
  NEEDEDKDOWN="$NEEDEDK" # so will not trigger warning
 fi
 #---
 if [ ! -f /tmp/pup_event_sizefreem ]; then
  /usr/local/pup_event/frontend_timeout &
  sleep 1
  [ ! -f /tmp/pup_event_sizefreem ]&& echo "Free space estimation error. Exiting" \
    > /tmp/petget/install_status && \
	. /usr/lib/gtkdialog/box_ok "$(gettext 'Pup_event_error')" error "$(gettext 'This is a rare pup_even error that fails to report the available free space. Just click on the free memory applet at the tray and try again. It should be OK after that.')" \
	&& clean_up && exit 1
 fi
 AVAILABLE=$(cat /tmp/pup_event_sizefreem | head -n 1 )
 if [ "$DL_PATH" -a ! "$DL_PATH" = "/root" ]; then
  if [ -f /tmp/download_pets_quietly -o -f /tmp/download_only_pet_quietly \
   -o "$(cat /var/local/petget/nd_category 2>/dev/null)" = "true" ]; then
   SAVEAVAILABLE=$(df -m "$DL_PATH"| awk 'END {print $4}')
  else
   SAVEAVAILABLE="$AVAILABLE" # so will not trigger warning
  fi
 else
  SAVEAVAILABLE="$AVAILABLE" # so will not trigger warning
 fi
 if [ -f /tmp/download_pets_quietly -o -f /tmp/download_only_pet_quietly ]; then
  [ "$SAVEAVAILABLE" != "$AVAILABLE" ] && AVAILABLE="$SAVEAVAILABLE"
 fi
 PACKAGES=$(cat /tmp/pkgs_to_install | cut -f 1 -d '|')
 DEPENDENCIES=$(cat /tmp/overall_dependencies 2>/dev/null | sort | uniq)
 [ "$AVAILABLE" = "0" -o  "$AVAILABLE" = "" ] && echo "No space left on device. Exiting" \
	> /tmp/petget/install_status && clean_up && exit 0
 #statusbar in main gui
 PERCENT=$((${NEEDEDK}*100/${AVAILABLE}))
 [ $PERCENT -gt 99 ] && PERCENT=99
 if [ -s /tmp/overall_pkg_size ] && [ $PERCENT = 0 ]; then PERCENT=1; fi
 echo "$PERCENT" > /tmp/petget/install_status_percent
 if [ "$(cat /tmp/pkgs_to_install /tmp/overall_dependencies 2>/dev/null)" = "" ]; then
  echo "" > /tmp/petget/install_status
 else
  cat /tmp/pkgs_to_install | cut -f1 -d '|' > /tmp/pkgs_to_install_bar
  if [ -f /tmp/install_pets_quietly -o -f /tmp/install_classic ]; then
   if [ "$(cat /var/local/petget/nd_category 2>/dev/null)" != "true" ]; then
    BARNEEDEDK=$( expr 2 \* ${NEEDEDK} \/ 3 )
    BARMSG="$(gettext 'to install')"
   else
    BARNEEDEDK=${NEEDEDK}
    BARMSG="$(gettext 'to install (and keep pkgs)')"
   fi
  else
   BARNEEDEDK=${NEEDEDK}
   BARMSG="$(gettext 'to download')"
  fi
  echo "$(gettext 'Packages (with deps)'): $(cat /tmp/pkgs_to_install_bar /tmp/overall_dependencies 2>/dev/null |sort | uniq | wc -l)    -   $(gettext 'Required space') ${BARMSG}: ${BARNEEDEDK}MB   -   $(gettext 'Available'): ${AVAILABLE}MB" > /tmp/petget/install_status
 fi
 #Check if enough space on system
 if [ "$NEEDEDKDOWN" -ge "$SAVEAVAILABLE" -a "$AVAILABLE" -ge "$NEEDEDK" ]; then
  ACTION_MSG="$(gettext 'Although there is sufficient space to install the packages, there is no space in your download folder, ')$DL_PATH$(gettext ', to save the packages (including dependencies). ')"
  AVAILABLE="$SAVEAVAILABLE"
 fi
 if [ "$NEEDEDK" -ge "$AVAILABLE" -o "$NEEDEDKDOWN" -ge "$SAVEAVAILABLE" ]; then
  export PPM_error='
  <window title="PPM - '$(gettext 'Space needed')'" icon-name="gtk-no">
  <vbox space-expand="true" space-fill="true">
    <frame '$(gettext 'Error')'>
      <hbox homogeneous="true">
        '"`/usr/lib/gtkdialog/xml_pixmap dialog-error.svg popup`"'
      </hbox>
      <hbox border-width="10" homogeneous="true">
        <vbox space-expand="true" space-fill="true">
          <text xalign="0" use-markup="true"><label>"'$(gettext 'Available space on your system is')' '${AVAILABLE}' MB. <b>'${ACTION_MSG}'</b> '$(gettext 'Please delete some files or resize your puppy save area or change package save location, as appropriate.')'"</label></text>
          <vbox scrollable="true" shadow-type="0" height="150" width="350" space-expand="true" space-fill="true">
            <text xalign="0"><label>"'$PACKAGES'"</label></text>
            <text xalign="0"><label>"'$DEPENDENCIES'"</label></text>
          </vbox>
        </vbox>
       </hbox>
    </frame>
    <hbox space-expand="false" space-fill="false">
      <button>
        '"`/usr/lib/gtkdialog/xml_button-icon ok`"'
        <label>" '$(gettext 'Ok')' "</label>
      </button>
    </hbox>
  </vbox>
  </window>'
  gtkdialog --center -p PPM_error
  killall yaf-splash
  if [ ! -f /tmp/install_classic ]; then
   echo "" > /tmp/petget/install_status
   echo 0 > /tmp/petget/install_status_percent
   if [ "$(ls /tmp/*_pet{,s}_quietly /tmp/install_classic |wc -l)" -eq 1 ]; then
	for MODE in $(ls /tmp/*_pet{,s}_quietly /tmp/install_classic)
	do
	 mv $MODE $MODE.bak
	done
   fi
   clean_up
   mv $MODE.bak $MODE
  else
   . /usr/lib/gtkdialog/box_yesno "$(gettext 'Last warning')" "$NEEDEDK $(gettext 'of the ') $AVAILABLE $(gettext ' available MB will be used to install the package(s) you selected.')" "<b>$(gettext 'It is NOT sufficent. Please exit now.')</b>"  "$(gettext 'However, if you are sure about the spep-by-step process, take a risk.')" "$(gettext 'Do you want to cancel installation?')"
   if [ "$EXIT" = "yes" ]; then
    echo 0 > /tmp/petget/install_status_percent
    echo "" > /tmp/petget/install_status
    if [ "$(ls /tmp/*_pet{,s}_quietly /tmp/install_classic |wc -l)" -eq 1 ]; then
	 for MODE in $(ls /tmp/*_pet{,s}_quietly /tmp/install_classic)
	 do
	  mv $MODE $MODE.bak
	 done
    fi
    clean_up
    mv $MODE.bak $MODE
   else
    echo "good luck"
   fi
  fi
 fi
}
export -f check_total_size

status_bar_func () {
 while $1 ; do
  TOTALPKGS=$(cat /tmp/pkgs_to_install_bar /tmp/overall_dependencies 2>/dev/null |sort | uniq | wc -l)
  DONEPGKS=$(cat /tmp/overall_package_status_log 2>/dev/null | wc -l)
  PERCENT=$( expr $DONEPGKS \* 100 \/ $TOTALPKGS )
  [ $PERCENT = 100 ] && PERCENT=99
  echo $PERCENT > /tmp/petget/install_status_percent
  sleep 0.3
  [ -f /tmp/ppm_reporting ] && break
 done
}
export -f status_bar_func
 
install_package () {
 [ "$(cat /tmp/pkgs_to_install)" = "" ] && exit 0
 cat /tmp/pkgs_to_install | tr ' ' '\n' > /tmp/pkgs_left_to_install
 rm -f /tmp/overall_package_status_log
 echo 0 > /tmp/petget/install_status_percent
 echo "$(gettext "Calculating total required space...")" > /tmp/petget/install_status
 [ ! -f /root/.packages/skip_space_check ] && check_total_size
 status_bar_func &
 while read LINE; do
   REPO=$(echo $LINE | cut -f 2 -d '|')
   echo "$REPO" > /tmp/petget/current-repo-triad
   TREE1=$(echo $LINE | cut -f 1 -d '|')
   if [ -f /tmp/install_quietly ];then
    if [  "$(grep $TREE1 /root/.packages/user-installed-packages 2>/dev/null)" = "" \
     -a -f /tmp/install_pets_quietly ]; then
     if [ "$(cat /var/local/petget/nt_category 2>/dev/null)" = "true" ]; then
     /usr/local/petget/installpreview.sh
     else
	  rxvt -title "$VTTITLE... $(gettext 'Do NOT close')" \
	  -fn -misc-fixed-medium-r-semicondensed--13-120-75-75-c-60-*-* -bg black \
      -fg grey -geometry 80x5+50+50 -e /usr/local/petget/installpreview.sh
     fi
    else
     if [ "$(cat /var/local/petget/nt_category 2>/dev/null)" = "true" ]; then
     /usr/local/petget/installpreview.sh
     else
	  rxvt -title "$VTTITLE... $(gettext 'Do NOT close')" \
	  -fn -misc-fixed-medium-r-semicondensed--13-120-75-75-c-60-*-* -bg black \
      -fg grey -geometry 80x5+50+50 -e /usr/local/petget/installpreview.sh
     fi
    fi
   else
    /usr/local/petget/installpreview.sh
   fi
   /usr/local/petget/finduserinstalledpkgs.sh
   sed -i "/$TREE1/d" /tmp/pkgs_left_to_install
 done < /tmp/pkgs_to_install
 sync
 report_results
 clean_up
}
export -f install_package

recalculate_sizes () {
	if [ "$(grep changed /tmp/mode_changed 2>/dev/null)" != "" ]; then
		rm -f /tmp/overall_*
		for LINE in $(cat /tmp/pkgs_to_install)
		do
			/usr/local/petget/installed_size_preview.sh $LINE ADD
		done
	else
		echo "cool!"
	fi
	rm -f /tmp/mode_changed
}
export -f recalculate_sizes

wait_func () {
	. /usr/lib/gtkdialog/box_splash -close never -text "$(gettext 'Please wait, calculating total required space for the installation...')" &
	X1PID=$!
	recalculate_sizes
	while true ; do
		sleep 0.2
		[ "$(ps -eo pid,command | grep installed_size_preview | grep -v grep)" = "" ] && break
	done
	kill -9 $X1PID
}
export -f wait_func

case "$1" in
	check_total_size)
		touch /tmp/install_quietly #avoid splashes
		check_total_size
		;;
	"$(gettext 'Auto install')")
		wait_func
		rm -f /tmp/install_pets_quietly
		rm -f /tmp/install_classic 2>/dev/null
		rm -f /tmp/download_pets_quietly 2>/dev/null
		rm -f /tmp/download_only_pet_quietly 2>/dev/null
		touch /tmp/install_quietly
		touch /tmp/install_pets_quietly
		cp -a /tmp/pkgs_to_install /tmp/pkgs_to_install_done
		VTTITLE=Installing
		export VTTITLE
		install_package
		unset VTTITLE
		;;
	"$(gettext 'Download packages (no install)')")
		wait_func
		rm -f /tmp/install_pets_quietly
		rm -f /tmp/install_classic 2>/dev/null
		rm -f /tmp/download_pets_quietly 2>/dev/null
		rm -f /tmp/download_only_pet_quietly 2>/dev/null
		touch /tmp/install_quietly
		touch /tmp/download_only_pet_quietly 
		cp -a /tmp/pkgs_to_install /tmp/pkgs_to_install_done
		VTTITLE=Downloading
		export VTTITLE
		install_package
		unset VTTITLE
		;;
	"$(gettext 'Download all (packages and dependencies)')")
		wait_func
		rm -f /tmp/install_pets_quietly
		rm -f /tmp/install_classic 2>/dev/null
		rm -f /tmp/download_pets_quietly 2>/dev/null
		rm -f /tmp/download_only_pet_quietly 2>/dev/null
		touch /tmp/install_quietly
		touch /tmp/download_pets_quietly 
		cp -a /tmp/pkgs_to_install /tmp/pkgs_to_install_done
		VTTITLE=Downloading
		export VTTITLE
		install_package
		unset VTTITLE
		;;
	"$(gettext 'Step by step installation (classic mode)')")
		wait_func
		rm -f /tmp/install{,_pets}_quietly
		rm -f /tmp/download_pets_quietly 2>/dev/null
		rm -f /tmp/download_only_pet_quietly 2>/dev/null
		touch /tmp/install_classic
		cp -a /tmp/pkgs_to_install /tmp/pkgs_to_install_done
		install_package
		;;
esac
