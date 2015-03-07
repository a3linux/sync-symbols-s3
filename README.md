Sync symbols from Mozilla's old NFS store to S3.

```./sync_symbols_s3.py``` runs a "quick" sync, which uses the .txt index files.

```./sync_symbols_s3.py -f``` runs a "full" sync

See ```cron.sh``` for an example shell script. Should be run with locking, like:

```
# Sync symbols to S3 (fast)
*/5 * * * * cd /home/socorro/sync-symbols-s3 && flock -n /tmp/sync-symbols-s3.lock -c ./cron.sh >> /home/socorro/sync-symbols-s3/sync_symbols.log
# Sync symbols to S3 (full)
05 00 * * * cd /home/socorro/sync-symbols-s3 && flock -n /tmp/sync-symbols-s3-full.lock -c ./cron.sh -f >> /home/socorro/sync-symbols-s3/sync_symbols_full.log

```
