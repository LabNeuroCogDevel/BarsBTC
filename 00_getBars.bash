rsync -Lrzvhi foranw@wallace:/data/Luna1/Raw/MRCTR/ subjs/   \
  --include='[0-9][0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' \
  --include='*/*mprage*' \
  --include='*/*BarsReward*/' \
  --include='*/*mprage*/*' \
  --include='*/*BarsReward*/*' \
  --exclude='*' \
  #--exclude '*/*'
