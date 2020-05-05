#!/bin/bash

#  publish.sh
#  V2rayU
#
#  Created by yanue on 2019/7/18.
#  Copyright © 2019 yanue. All rights reserved.
source ./release.sh


read -p "Please enter description: " release_note
pushRelease ${release_note}
generateAppcast ${release_note}
commit

rm -rf "${DMG_TMP}" "${APP_PATH}" "${V2rayU_RELEASE}"
echo "Done"
