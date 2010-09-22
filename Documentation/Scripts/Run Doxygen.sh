#!/bin/sh

# Run Doxygen.sh
# BMScriptTest
#
# Created by Andre Berg on 09.10.09.
# Copyright 2009 Berg Media. All rights reserved.

# Build the doxygen documentation for the project and load the docset into Xcode.
#
# Use the following to adjust the value of the $DOXYGEN_PATH User-Defined Setting:
#   Binary install location: /Applications/Doxygen.app/Contents/Resources/doxygen
#   Source build install location: /usr/local/bin/doxygen

# If the config file doesn't exist, run 'doxygen -g $SOURCE_ROOT/doxygen.config' to 
#  a get default file.

#run doxygen to generate the makefile based on our DOXYFILE

if [[ ! -e "${DOXYGEN_PATH}" ]]; then
    if [[ -e "/Applications/Doxygen.app/Contents/Resources/doxygen" ]]; then
        DOXYGEN_PATH="/Applications/Doxygen.app/Contents/Resources/doxygen"
    else
        echo "Error: Doxygen executable not found at path: '${DOXYGEN_PATH}' or at default path: '/Applications/Doxygen.app/Contents/Resources/doxygen'."
        echo "Please either set the proper path with the DOXYGEN_RES_PATH variable in the Documentation.xcconfig or install Doxygen to the default path."
        echo "Aborting..."
        exit 1
    fi
fi

"${DOXYGEN_PATH}" "${DOCROOT}/${DOXYFILE}"
exit 0
