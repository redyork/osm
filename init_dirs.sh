#!/bin/bash

source .env
#echo $APP_DIR

mkdir -p $APP_DIR/tiles $APP_DIR/import $APP_DIR/tmp/osmosis $APP_DIR/osmosis $APP_DIR/postgres $APP_DIR/logs &2>1

chmod 777 $APP_DIR/tiles $APP_DIR/postgres $APP_DIR/logs $APP_DIR/tmp $APP_DIR/tmp/osmosis &2>1



