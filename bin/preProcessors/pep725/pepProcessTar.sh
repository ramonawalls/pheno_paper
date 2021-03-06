#!/bin/bash
# NOTE: Copy this script to wherever you want your input data to be stored
#Script for processing PEP725 data and organizing into respective directories
for tarName in $(ls -1 *.tar); do
  dirName=${tarName//\.tar}
  echo "processing $tarName"
  mkdir $dirName
  mv $tarName $dirName
  cd $dirName
  tar xvf $tarName
  rm $tarName
  cd ..
done
