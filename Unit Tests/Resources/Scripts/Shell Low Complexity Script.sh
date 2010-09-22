#!/bin/bash
#
# Low Complexity Shell Script.sh
# BMScriptTest
#
# Created by Andre Berg on 21.09.10.
# Copyright 2010 Berg Media. All rights reserved.

if [[ -f "/System/Library/CoreServices/SystemVersion.plist" ]]; then
  echo 'File exists!' | sed s/File/SystemVersion.plist/
else
  echo 'File does not exist!' | sed s/File/SystemVersion.plist/
fi