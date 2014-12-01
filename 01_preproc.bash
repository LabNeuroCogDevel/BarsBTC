#!/usr/bin/env bash

# 1. preproc mprage if needed
# 2. preproc functional

export AFNI_AUTOGZIP="YES"
export FSLOUTPUTTYPE="NIFTI_GZ"

# go to script directory
scriptdir=$(cd $(dirname $0); pwd)
cd $(dirname $0)

## what do the final files look like
# with these known, we can skip finished visits
# enabling quick resume
finalmprage=mprage_final.nii.gz 
finalwarp=mprage_final_warpfield.nii.gz
finalrun=

# get MAXJOBS and WAITTIME.
# -- done this way, the settings can change mid run
settingsrc="settingsrc.sh"
source $settingsrc


function preprocess {
  subjdir="$1"

  ## get subj/date as variables
  subjdate=$(basename $subjdir)
  subj=${subjdate%%_*}
  vdate=${subjdate##*_}

  echo "$subjdate $subj $vdate"


  ## PROCESS MPRAGE
  #  ... if needed
  mpragedir="$(find $subjdir -type d -maxdepth 1 -name "axial_mprage*" | sed 1q)"
  [ -z "$mpragedir" -o ! -d "$mpragedir" ] && echo "NO mpragedir in $subjdir" && return

  mprage="$(find $subjdir -name "$finalmprage" | sed 1q)"
  warprage="$(find $subjdir -name "$finalwarp" | sed 1q)"

  # if we do not have warprage or mprage
  if [  -z "$mprage"   -o \
        -z "$warprage"  ]; then
        cd $mpragedir
        echo "T1 $subj $vdate"
        preprocessMprage -d y -o mprage_final.nii.gz 
        cd -
  fi

  # test that mprage preprocessing worked
  mprage="$(find $subjdir -name "$finalmprage" | sed 1q)"
  warprage="$(find $subjdir -name "$finalwarp" | sed 1q)"
  if [  -z "$mprage"   -o \
        -z "$warprage"  ]; then
        echo "failed to create $finalmprage and $finalwarp for visit $subjdate"
        return
  fi

  ## PREPROCESS FUNCTIONAL 
  # for each run of bars reward
  for BarsRun in $subjdir/BarsRewards_AntiX4_384x384*; do
    cd $BarsRun
    echo "T2 $subj $vdate"
    echo "preprocessFunctional $BarsRun"
    cd -
  done


}

function exiterror {
 echo $@
 exit 1;
}

## do not spam the system with jobs
# wait until less than max jobs are queued
function waitforjobs {
  message="$@"

  # make sure we have a MAXJOBS
  [ -z "$settingsrc" -o ! -r  "$settingsrc" ] && exiterror "cannot find a settingsrc file"
  source $settingsrc
  [ -z "$MAXJOBS"   -o -z "$WAITTIME" ] && exiterror "cannot read MAXJOBS or WAITITME form $settingrc file"
  
  # wait until we clear below MAXJOBS
  njobs=$(jobs -p | wc -l)
  while [[ "$njobs" -ge "$MAXJOBS" ]]; do
    echo
    echo  "have ${njobs// } jobs, waiting $WAITTIME"
    jobs | sed 's/^/	/'
    echo $message
    echo
    sleep $WAITTIME;
    njobs=$(jobs -p | wc -l)
  done
}


waitforjobs # no jobs to wait for, but makes sure settings are correct

for subjdir in $scriptdir/subjs/1*_*/; do

  preprocess $subjdir &
  

  waitforjobs "last visit submitted: $subjdir"
done

wait

#mail
