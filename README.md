Sync symbols from Mozilla's old NFS store to S3.

```./sync_symbols_s3.py``` runs a "quick" sync, which uses the .txt index files.

```./sync_symbols_s3.py -f``` runs a "full" sync

See ```cron.sh``` for an example shell script.
