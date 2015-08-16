#!/bin/bash

################################################################################
#
# tests the 'remapuser during startup' feature
#
# (*) must be run as root to generate test dirs and files with different users
# (*) must run from within tests directory
# (*) to get just the test results: sudo ./run-tests.sh > /dev/null
#
#-------------------------------------------------------------------------------
#
# The MIT License (MIT)
#
# Copyright (c) 2015 Tom Nussbaumer <thomas.nussbaumer@gmx.net>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
################################################################################
if [ "$(id -u)" != "0" ]; then
   echo "[ERROR] $0 must be run as root" 1>&2
   exit 1
fi

if [ ! -f '../REPO_AND_VERSION' ]; then
   echo "[ERROR] please run this from within tests directory" 1>&2
   exit 2
fi

CWD=$(pwd)
OWNER=$(ls -ld $CWD | awk '{print $3}')
OUID=$(id -u "$OWNER")
OGID=$(id -u "$OWNER")
echo "### owner of local directory:"
id "$OWNER"


TESTDIR="$CWD/test"
mkdir "$TESTDIR"
chown $OUID:$OGID "$TESTDIR"
cd "$TESTDIR"

TMP=$OUID-$OGID

mkdir dir-root
mkdir dir-9999-9999
mkdir dir-$TMP
touch dir-root/file-root
touch dir-9999-9999/file-9999-9999
touch dir-$TMP/file-$TMP
chown -R 9999:9999 dir-9999-9999
chown -R $OUID:$OGID dir-$TMP

chmod 700 dir-root/file-root
chmod 700 dir-9999-9999/file-9999-9999
chmod 700 dir-$TMP/file-$TMP

echo "### produced testdata:"
ls -lan

## IMPORTANT NOTE: don't map into $HOME if your external data hold files owned
#                  by UID 9999. This files will be automatically changed to the
#                  new user by the system when calling 'usermod -u'
docker run -ti --rm -v "$TESTDIR:/test" "$(cat '../../REPO_AND_VERSION')" \
       /sbin/my_init -- /sbin/remapuser app $OUID $OGID \
       bash -c 'echo "### internal user:"; id; cd /test; echo "### content after mount:"; ls -lan; rm -rf *; echo "### content after rm:"; ls -lan'

echo "### after docker run:"
ls -lan

testDirExists () {
  if [ -d $1 ]; then
     echo "$2 $1 not deleted" 1>&2
  else
     echo "$3 $1 deleted" 1>&2
  fi
}
testFileExists () {
  if [ -f $1 ]; then
     echo "$2 $1 not deleted" 1>&2
  else
     echo "$3 $1 deleted" 1>&2
  fi
}

testDirExists  dir-root                     "[PASS]" "[FAIL]"
testDirExists  dir-9999-9999                "[PASS]" "[FAIL]"
testDirExists  dir-$TMP                     "[FAIL]" "[PASS]"
testFileExists dir-root/file-root           "[PASS]" "[FAIL]"
testFileExists dir-9999-9999/file-9999-9999 "[PASS]" "[FAIL]"
testFileExists dir-$TMP/file-$TMP           "[FAIL]" "[PASS]"

cd - >/dev/null 2>&1
rm -rf "$TESTDIR"

