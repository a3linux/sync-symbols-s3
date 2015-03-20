#!/bin/bash

#set -e

. /home/socorro/.virtualenvs/aws/bin/activate

PRIVATE_BUCKET="org.mozilla.crash-stats.symbols-private/v1"
PUBLIC_BUCKET="org.mozilla.crash-stats.symbols-public/v1"
TOP_DIR="/mnt/socorro/symbols"
PRIVATE_DIRS="symbols_adobe"
PUBLIC_DIRS="symbols_b2g symbols_camino symbols_fedora \
             symbols_ffx symbols_geeksphone symbols_leo \
             symbols_mob symbols_opensuse symbols_os \
             symbols_penelope symbols_sbrd symbols_sea \
             symbols_solaris symbols_spreadtrum \
             symbols_t2mobile symbols_tbrd symbols_tclpartner \
             symbols_thirdparty symbols_ubuntu symbols_xr \
             symbols_zte"

function full_sync_s3 {
    dirs=$1
    bucket=$2
    for dir in $dirs; do
        pushd $TOP_DIR/$dir > /dev/null
        echo "Syncing $dir to $bucket"
        aws s3 sync . s3://$bucket/
        popd > /dev/null
    done
    wait
}

function quick_sync_s3 {
    dirs=$1
    bucket=$2
    for dir in $dirs; do
        # XXX workaround for bug 1144865
        if [ "$dir" == "symbols_b2g" ]; then
            pushd $TOP_DIR/$dir
            if [ ! -f /tmp/bug1144865 ]; then
                yesterday=$(date -d 'yesterday' +%Y%m%d)
                touch -t ${yesterday}0000 /tmp/bug1144865
            fi
            find libxul.so/* -maxdepth 1 -type d -newer /tmp/bug1144865 | while read f; do
                aws s3 cp $f/libxul.so.sym s3://$bucket/$f/libxul.so.sym
            done
            touch /tmp/bug1144865
            popd
        fi
        echo "Syncing $dir to $bucket"
        ./sync_symbols_s3.py -p $TOP_DIR/$dir -b $bucket -f $dir.p &
    done
    wait
}

if [ "$1" == "-f" ]; then
    full_sync_s3 "$PRIVATE_DIRS" $PRIVATE_BUCKET
    full_sync_s3 "$PUBLIC_DIRS" $PUBLIC_BUCKET
else
    quick_sync_s3 "$PUBLIC_DIRS" $PUBLIC_BUCKET
fi
