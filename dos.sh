#!/bin/sh

if ! [ -x "$(command -v dosbox-x)" ]; then
  dosbox --conf dosbox.conf 
else
  dosbox-x --conf dosbox-x.conf 
fi

