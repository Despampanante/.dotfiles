#find config/* -prune -exec \
  #sh -c 'ln -s $(realpath {}) ~/.config/' \;
#find home/.* -prune -type f -exec \
  #sh -c 'ln -s $(realpath {}) ~' \;
#echo Done!

for file in config/*; do 
  echo "$file"
  if [ -d $file ]; then
    echo "test"
    echo $(basename $file)
    echo "test"
  fi
done



