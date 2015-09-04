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
mkdir dir-$TMP
touch dir-root/file-root
touch dir-$TMP/file-$TMP
chown -R $OUID:$OGID dir-$TMP

chmod 700 dir-root/file-root
chmod 700 dir-$TMP/file-$TMP

echo "### produced testdata:"
ls -lan

# IMPORTANT NOTE: 
#
# don't bind mount anything into $HOME! This files will be automatically changed 
# to the new user by the system when calling 'usermod -u'
docker run -ti --rm -v "$TESTDIR:/test" "$(cat '../../REPO_AND_VERSION')" \
       my_init -- remapuser app $OUID $OGID \
       bash -c 'echo "### internal user:"; id; cd /test; echo "### content after mount:"; ls -lan; rm -rf *; echo "### content after rm:"; ls -lan'

echo "### after docker run:"
ls -lan

PASS="[PASS]"
FAIL="[FAIL]"

outResult () {
  tput bold
  if [ $1 = "$PASS" ]; then
    tput setaf 2
    tput setab 0
  else
    tput setaf 1   
    tput setab 0
  fi
  echo -n "$1"
  tput sgr0
  echo -n " "
}

testDirExists () {
  if [ -d $1 ]; then
     outResult $2
     echo "$1 not deleted" 1>&2
  else
     outResult $3
     echo "$1 deleted" 1>&2
  fi
}
testFileExists () {
  if [ -f $1 ]; then
     outResult $2
     echo "$1 not deleted" 1>&2
  else
     outResult $3
     echo "$1 deleted" 1>&2
  fi
}

testDirExists  dir-root                     "$PASS" "$FAIL"
testDirExists  dir-$TMP                     "$FAIL" "$PASS"
testFileExists dir-root/file-root           "$PASS" "$FAIL"
testFileExists dir-$TMP/file-$TMP           "$FAIL" "$PASS"

cd - >/dev/null 2>&1
rm -rf "$TESTDIR"
