#!/bin/bash

echo "Patch python 2.7 : add lzma"
echo "  (You can revert this with: 'patch -R /usr/lib/python2.7/site-packages/debian/debfile.py < patch_spacewalk_debfile_lzma.diff')"
patch /usr/lib/python2.7/site-packages/debian/debfile.py < patch_spacewalk_debfile_lzma.diff
