#!/usr/bin/env python
"""
A quick sync script for symbols from NFS->S3

We can't simply record the time our sync script ran and find all newer files 
since files with timestamps in the past may appear. So, keep track of all .txt
index files that we encounter, and only sync files when there are additions
to that set.
"""

import argparse
import datetime
import glob
import os
import pickle

def find_index_files(path):
    today_timestamp = datetime.datetime.now().strftime('%Y%m%d')
    yesterday = datetime.datetime.now() - datetime.timedelta(days=1)
    yesterday_timestamp = yesterday.strftime('%Y%m%d')

    index_files = glob.glob('%s/*%s*.txt' % (path, yesterday_timestamp))
    index_files += glob.glob('%s/*%s*.txt' % (path, today_timestamp))

    return set(index_files)

def sync(index_files, path, bucket):
    cwd = os.getcwd()
    os.chdir(path)
    for file in index_files:
        with open(file, 'r') as f:
            base, fname = os.path.split(file)
            cmd = 'aws s3 cp %s s3://%s/%s' % (
                fname, bucket, fname)
            os.popen(cmd)
            print 'running cmd: %s' % cmd
            for line in f:
                sym_file = line.strip()
                cmd = 'aws s3 cp %s s3://%s/%s' % (
                    sym_file, bucket, sym_file)
                print 'running cmd: %s' % cmd
                os.popen(cmd)
    os.chdir(cwd)

def main(path, bucket, state_file):
    old_index_files = set()
    try:
        old_index_files = pickle.load(open(state_file, 'r'))
    except:
        print 'WARN: no state file "%s"' % state_file
    new_index_files = find_index_files(path)

    index_files = new_index_files - old_index_files
    sync(index_files, path, bucket)
    pickle.dump(new_index_files, open(state_file, 'wb'))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Quick symbol sync script")
    parser.add_argument('-p', '--path', action="store", dest="path")
    parser.add_argument('-b', '--bucket', action="store", dest="bucket")
    parser.add_argument('-f', '--state-file', action="store", dest="state_file")
    results = parser.parse_args()
    main(results.path, results.bucket, results.state_file)
