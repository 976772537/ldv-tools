#!/bin/bash

LDVS_HOME=`readlink -f \`dirname $0\`/../`;
LDVS_DIST=$LDVS_HOME/dist;
LDVS_CLIENT=$LDVS_DIST/vsClient.jar;

LDVS_CONFIG=`readlink -f $1`;
#
# build server
#
cd $LDVS_HOME;
ant;

#
# start server
#
java -jar $LDVS_CLIENT $LDVS_CONFIG




