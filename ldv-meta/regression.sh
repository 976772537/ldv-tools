#!/bin/bash

#
# Example:
#
#LANG=C LDV_DEBUG=100 DBHOST=10.10.2.82 DBNAME=qatest DBUSER=qatest DBPASS=qatest TEST=big/regr-task-big-iceberg REVISION=9d5944528e8c253487f7b2cb74146a55f4dc8dcd LDV_HOME=/mnt/second/iceberg/ldv-inst/rtest LDV_WORKDIR=/home/iceberg/rtest LDV_REPO=/home/iceberg/ldvtest/regr_script_test/ldv-tools /home/iceberg/ldv-tools/qaserv/regression.sh
#
# LDV-REPO - git clone git://itgdev.igroup.ispras.ru/ldv-tools.git
# 
# mailx|ssmtp|nullmailer etc for send reports
#
#

#
# database options
#
LDVDB_NAME=${DBNAME:-ldvtest};
LDVDB_USER=${DBUSER:-ldvuser};
LDVDB_PASS=${DBPASS:-ldvpass};
LDVDB_HOST=${DBHOST:-localhost};

LDV_MAIL=${LDV_MAIL:-ldv-project@ispras.ru};

LDV_TEST_SET=${TEST:-small/regr-task-small};

LDV_HOME=${LDV_HOME:-/home/ldv-inst};
LDV_WORKDIR=${LDV_WORKDIR:-$HOME/ldv-test-workdir};

LDV_REGR_TEST="$LDV_HOME/bin/regr-test.pl";
LDV_REPO=${LDV_REPO:-$HOME/ldv-tools};

LDV_REVISION=${REVISION:-9d5944528e8c253487f7b2cb74146a55f4dc8dcd};

LDV_REGR_TESTSETS_DIR="$LDV_HOME/ldv-tests/regr-tests/test-sets/";
LDV_TEST_SET_PATH="$LDV_REGR_TESTSETS_DIR/$LDV_TEST_SET";

LDV_WORK_REPORT_FILENAME="report";
LDV_WORK_RESULTS_DIRNAME="results";
LDV_WORK_WORKDIR_DIRNAME="workdir";

MAIL_BIN=mail;
#
# scan and test environment parameters
#
if [ ! -n "$LDV_WORKDIR" ]; then
	echo "ERROR: Parameter \"LDV_WORKDIR\" - is null.";
	exit 2;
fi;
LDV_WORKDIR=`readlink -f $LDV_WORKDIR`;
if [ $? -ne 0 ]; then
	echo "ERROR: Failed to read abs-path for workdir: \"$LDV_WORKDIR\"."
	exit 2;
fi;
if [ -d "$LDV_WORKDIR" ]; then
	echo "WARNING: Workdir already exists. I am rewrite it.";
fi;
if [ ! -n "$LDV_REPO" ]; then
	echo "ERROR: Parameter \"LDV_REPO\" - is null..";
	exit 2;
fi;
if [ ! -d "$LDV_REPO" ]; then
	echo "ERROR: Dir \"LDV_REPO\" - not exists.";
	exit 2;
fi;


#---------------------------------------------------------------------------

#
# Print info:
#
echo "INFO: For correct work regression script:";
echo "INFO:  1. Install mysql server.";
echo "INFO:  2. Start mysql server daemon: \"sudo /etc/init.d/mysqld\".";
echo "INFO:  3. Connect to db server as root like this: \"mysql -u root ...\".";
echo "INFO:  4. Create db for stats: \"CREATE DATABASE ldvdb;\".";
echo "IFNO:  5. Create user for stats db: \"CREATE USER 'ldvdbuser'@'localhost' IDENTIFIED BY 'ldvdbpass';\".";
echo "INFO:  6. Add priviledges: \"GRANT ALL PRIVILEGES ON ldvdb.* TO 'ldvdbuser'@'localhost' WITH GRANT OPTION;\".";
echo "IFNO:  7. Update privileges: \"FLUSH PRIVILEGES;\".";
echo "INFO:  8. Write all parameters (dbname, dbhost, dbuser, dbpass) to regression script.";
echo "INFO:  9. Clone git repo: \"git clone git://itgdev.igroup.ispras.ru/ldv-tools.git\" and set LDV_REPO";

#
# Create all directories
#
REPORT="$LDV_WORKDIR/$LDV_WORK_REPORT_FILENAME";
if [ -d "$LDV_WORKDIR" ]; then
        echo "NORMAL: Clean workdir for regression test: \"$LDV_WORKDIR\".";
        rm -fr $LDV_WORKDIR/*;
        if [ $? -ne 0 ]; then
                echo "ERROR: Can't clean directory for regression tests: \"$LDV_WORKDIR\".";
                exit 1;
        fi;
fi;

#echo "NORMAL: Create directories for regression test.";
#mkdir -p $RT_RESULTS_DIR;
#if [ $? -ne 0 ]; then
#        echo "ERROR: Can't create working dirs for regression tests: \"$RT_RESULTS_DIR\".";
#        exit 1;
#fi;
#mkdir -p $RT_WORKDIR_DIR;
#if [ $? -ne 0 ]; then
#        echo "ERROR: Can't create working dirs for regression tests: \"$RT_WORKDIR_DIR\".";
#        exit 1;
#fi;

#
# install distr
#
echo "NORMAL: Make checkout.";
cd $LDV_REPO;
git checkout $LDV_REVISION;
if [ $? -ne 0 ]; then
	echo "Regression test on revision $LDV_REVISION failed on checkout stage." | $MAIL_BIN -s "Regression tests results." $LDV_MAIL;
	echo "ERROR: Build failed during revision checkout.";
	exit 2;
fi;
echo "NORMAL: Make submodule init.";
git submodule init;
if [ $? -ne 0 ]; then
	echo "Regression test on revision $LDV_REVISION failed on submodule init stage." | $MAIL_BIN -s "Regression tests results." $LDV_MAIL;
	echo "ERROR: Build failed during revision submodule init.";
	exit 2;
fi;
echo "NORMAL: Make submodule update.";
git submodule update;
if [ $? -ne 0 ]; then
	echo "Regression test on revision $LDV_REVISION failed on submodule update stage." | $MAIL_BIN -s "Regression tests results." $LDV_MAIL;
	echo "ERROR: Build failed during revision submodule init.";
	exit 2;
fi;
echo "NORMAL: Make ldv-distr.";
make >> $REPORT 2>&1
if [ $? -ne 0 ]; then
	echo "Regression test on revision $LDV_REVISION failed on make stage." | $MAIL_BIN -s "Regression tests results." $LDV_MAIL;
        echo "ERROR: Build failed on \"make\" stage.";
        exit 1;
fi;
echo "NORMAL: Install ldv-distr.";
prefix=$LDV_HOME make install-all >> $REPORT 2>&1
if [ $? -ne 0 ]; then
	echo "Regression test on revision $LDV_REVISION failed on install stage." | $MAIL_BIN -s "Regression tests results." $LDV_MAIL;
        echo "ERROR: Build failed on \"make install-all\" stage.";
        exit 1;
fi;

#
# And now start regression tests;
#
cd $LDV_WORKDIR;
echo "NORMAL: Start regression test-set: \"$LDV_TEST_SET\".";
date;
echo "INFO: rm -fr launcher-working-dir/ launcher-results-dir/ regr-task-new regr-test.diff && PATH=$PATH:$LDV_HOME/bin LDV_DEBUG=$LDV_DEBUG LDVDBHOSTTEST=$LDVDB_HOST LDVDBTEST=$LDVDB_NAME LDVUSERTEST=$LDVDB_USER LDVDBPASSWDTEST=$LDVDB_PASS $LDV_REGR_TEST --test-set $LDV_TEST_SET_PATH >> $REPORT 2>&1;";
rm -fr launcher-working-dir/ launcher-results-dir/ regr-task-new regr-test.diff && PATH=$PATH:$LDV_HOME/bin LDV_DEBUG=$LDV_DEBUG LDVDBHOSTTEST=$LDVDB_HOST LDVDBTEST=$LDVDB_NAME LDVUSERTEST=$LDVDB_USER LDVDBPASSWDTEST=$LDVDB_PASS $LDV_REGR_TEST --test-set $LDV_TEST_SET_PATH >> $REPORT 2>&1;
if [ $? -ne 0 ]; then
	echo "Regression test on revision $LDV_REVISION failed on testing stage." | $MAIL_BIN -s "Regression tests results." $LDV_MAIL;
	echo "ERROR: Regression test failed.";
	exit 1;
fi;
date;
if [ ! -f "regr-task-new" ]; then
	echo "Regression test on revision $LDV_REVISION failed on after testing stage." | $MAIL_BIN -s "Regression tests results." $LDV_MAIL;
	echo "ERROR: Regression test failed can't find regr-task-new.";
	exit 1;
fi; 
#echo "Regression test on revision $LDV_REVISION failed on after testing stage." | $MAIL_BIN -s "Regression tests results." $LDV_MAIL;
echo "NORMAL: Regression test successfully finished.";
exit 0;

