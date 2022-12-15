for file in config/* home/.*; do 
  if [[ $file -ef . ]] || [[ $file -ef home/.  ]]; then  continue; fi
  if [[ -d ~/.config/$(basename $file) ]] 
  then
    read -p "Delete ~/.config/$(basename $file)? " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then echo " Deleting..."; rm -r ~/.config/$(basename $file); else echo; echo "Not removed"; fi
  fi
  if [[ -f ~/$(basename $file) ]] 
  then
    read -p "Delete ~/$(basename $file)? " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then echo " Deleting..." ; rm ~/$(basename $file); else echo; echo "Not removed"; fi
  fi
done

find config/* -prune -exec \
  sh -c 'ln -s -v $(realpath {}) ~/.config/' \;
find home/.* -prune -type f -exec \
  sh -c 'ln -s -v $(realpath {}) ~' \;
echo Done!

