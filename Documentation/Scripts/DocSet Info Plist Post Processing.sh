#!/bin/bash

# DocSet Info Plist Post Processing.sh
# BMScriptTest
#
# Created by Andre Berg on 15.11.10.
# Copyright 2010 Berg Media. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

export PROJECT_VERSION_STRING=`cat "$TMPDIR/BMScriptDocSetTempFile.txt"`
export PROJECT_COPYRIGHT_STRING="Copyright © 2010 André Berg (Berg Media)"

"${DOCROOT}/setversion" -k "CFBundleVersion" "$PROJECT_VERSION_STRING" "CFBundleShortVersionString" "$PROJECT_VERSION_STRING" "NSHumanReadableCopyright" "${PROJECT_COPYRIGHT_STRING}" "$DOCROOT/$DOCSET_NAME/html/Info.plist"

exit 0