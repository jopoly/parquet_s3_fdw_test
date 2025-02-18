#!/bin/sh

./init.sh
rm -rf make_check.out || true

sed -i 's/REGRESS =.*/REGRESS = import_local import_server parquet_s3_fdw_local parquet_s3_fdw_server parquet_s3_fdw_post_local parquet_s3_fdw_post_server parquet_s3_fdw2 parquet_s3_fdw_modify_local parquet_s3_fdw_modify_server partition_local partition_server schemaless\/schemaless_local schemaless\/schemaless_server schemaless\/import_local schemaless\/import_server schemaless\/parquet_s3_fdw_local schemaless\/parquet_s3_fdw_server schemaless\/parquet_s3_fdw_post_local schemaless\/parquet_s3_fdw_post_server schemaless\/parquet_s3_fdw2 schemaless\/parquet_s3_fdw_modify_local schemaless\/parquet_s3_fdw_modify_server schemaless\/partition_local schemaless\/partition_server /' Makefile

if [[ "REGRESS_PREFIX=PGSpider" == $1 ]]; then
    sed -i 's/import_server/import_server ddlcommand_server/' Makefile
fi

make clean
make $1
make check $1 | tee make_check.out
