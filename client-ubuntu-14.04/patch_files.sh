#!/bin/bash

echo "Patch python 2.7 because of the error: 'cannot marshal None unless allow_none is enabled'"
echo "  (You can revert this with: 'patch -R /usr/lib/python2.7/xmlrpclib.py < patch_python2.7.diff')"
patch /usr/lib/python2.7/xmlrpclib.py < patch_python2.7.diff

echo "Fixing wrong splitting of ubuntu packages version in spacewalk"
echo "  (You can revert this with: 'patch -R /usr/share/rhn/up2date_client/debUtils.py < patch_spacewalk_ubuntu_package_version.diff')"
patch /usr/share/rhn/up2date_client/debUtils.py < patch_spacewalk_ubuntu_package_version.diff

