LDV_HOME=`readlink -f \`dirname $0\`/../../`;
LDV_INSTALL_TYPE=client
LDV_ONLINE_HOME=$LDV_HOME/ldv-online
LDV_ONLINE_CONF_DIR=$LDV_ONLINE_HOME/conf
LDV_ONLINE_SAMPLE_CONF=$LDV_ONLINE_CONF_DIR/$LDV_INSTALL_TYPE.conf.sample
LDV_ONLINE_CONF=$LDV_ONLINE_CONF_DIR/$LDV_INSTALL_TYPE.conf

USAGE_STRING="install-server.sh ...";

#
# Is client.conf and server.conf already exists then
# script run in update mode
#
if [ -f $LDV_ONLINE_CONF ]; then
	echo "Configuration files already exists. Update mode.";
	echo "LDV node installation successfully finished.";
else
	echo "First installation mode.";
	# read and test all needed options
	for arg in $@; do
	        case $arg in
			--workdir=*)
	                       	workdir=`echo $arg | sed 's/--workdir=//g'`;
	                       	if [ ! -n "$workdir" ]; then
	                       	        echo "ERROR: Parameter \"--workdir\" - is null. Please, setup it.";
	                       	        exit 1;
	                       	fi;
	               	;;
			--dbuser=*)
				dbuser=`echo $arg | sed 's/--dbuser=//g'` 
			;;
			--server=*)
				server=`echo $arg | sed 's/--server=//g'` 
			;;
			--dbpass=*)
				dbpass=`echo $arg | sed 's/--dbpass=//g'` 
			;;
			--dbname=*)
				dbname=`echo $arg | sed 's/--dbname=//g'` 
			;;
			--dbhost=*)
				dbhost=`echo $arg | sed 's/--dbhost=//g'` 
			;;
			*)  
                        	echo "ERROR: Unknown options: '$arg'.";
	                        echo $USAGE_STRING;
				exit 1;
        	        ;;  
	        esac
	done;
	if [ ! -n "$workdir" ]; then
		echo "Temp dir is null. Please, set up --workdir parameter.";
		exit 1;
	fi;
	if [ ! -n "$dbuser" ]; then
		echo "Database user is null. Please, set up --dbuser parameter.";
		exit 1;
	fi;
	if [ ! -n "$dbpass" ]; then
		echo "Database password is null. Please, set up --dbpass parameter.";
		exit 1;
	fi;
	if [ ! -n "$dbhost" ]; then
		echo "Database host is null. Please, set up --dbhost parameter.";
		exit 1;
	fi;
	if [ ! -n "$dbname" ]; then
		echo "Database name is null. Please, set up --dbname parameter.";
		exit 1;
	fi;
	if [ ! -n "$server" ]; then
		echo "Server address is null. Please, set up --server parameter.";
		exit 1;
	fi;

	if [ ! -d "$workdir" ]; then
		echo "Temp dir does't exists."; 
		echo "Try to create it...";
		mkdir -p $workdir/run && mkdir -p $workdir/logs;
		if [ $? -ne 0 ]; then
			echo "Can't create temp dir \"$workdir\".";
			exit 1;
		fi;
		echo "Temp dir successfully created.";
	fi; 
	workdir=`readlink -f $workdir`;
	if [ $? -ne 0 ]; then
		echo "ERROR: Can't read abs path for temp dir: \"$workdir\".";
		exit 1;
	fi;
	# change access for temp dir
	chmod a+w -R $workdir;
	if [ $? -ne 0 ]; then
		echo "ERROR: Can't change permissions for: \"$workdir\".";
		exit 1;
	fi;

	# and now copy configureation
	cp $LDV_ONLINE_SAMPLE_CONF $LDV_ONLINE_CONF;
	if [ $? -ne 0 ]; then
		echo "ERROR: Can't copy \"$LDV_ONLINE_SAMPLE_CONF\" to \"$LDV_ONLINE_CONF\".";
		exit 1;
	fi;
	# and setup new parameters
	sed -i -e "s|^LDVInstalledDir=.*$|LDVInstalledDir=$LDV_HOME|g" $LDV_ONLINE_CONF
	sed -i -e "s|^WorkDir=.*$|WorkDir=$workdir|g" $LDV_ONLINE_CONF;
	sed -i -e "s|^WSTempDir=.*$|WSTempDir=$workdir|g" $LDV_ONLINE_CONF;
	sed -i -e "s|^LDVServerAddress=.*$|LDVServerAddress=$server|g" $LDV_ONLINE_CONF;	
	# database options
	#if [ ! -n "$dbuser" ]; then dbuser=statsuserd; fi;
	#if [ ! -n "$dbpass" ]; then dbpass=statspass; fi;
	#if [ ! -n "$dbhost" ]; then dbhost=localhost; fi;
	#if [ ! -n "$dbname" ]; then dbname=statsdb; fi;
	sed -i -e "s|^StatsDBUser=.*$|StatsDBUser=$dbuser|g" $LDV_ONLINE_CONF;
	sed -i -e "s|^StatsDBPass=.*$|StatsDBPass=$dbpass|g" $LDV_ONLINE_CONF;
	sed -i -e "s|^StatsDBHost=.*$|StatsDBHost=$dbhost|g" $LDV_ONLINE_CONF;
	sed -i -e "s|^StatsDBName=.*$|StatsDBName=$dbname|g" $LDV_ONLINE_CONF;
	# load standart kernel sources
	#	wget http://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.32.21.tar.bz2
	KERNL_ORG_URL="http://www.kernel.org/pub/linux/kernel/v2.6/";
	KERNL_ORG_END_URL=".tar.bz2";
	mkdir $workdir/run && cd $workdir/run
	while read LINE; do
		if [ -n "`echo $LINE | grep env=`" ]; then
			KERNEL_URL=$KERNL_ORG_URL`echo "$LINE" | grep '^env=' |sed 's/env=//g' | sed 's/:.*//g'`$KERNL_ORG_END_URL;
			KERNEL_SRC=`echo "$LINE" | grep '^env=' |sed 's/env=//g' | sed 's/:.*//g'`$KERNL_ORG_END_URL;
			echo "Install default kernel sources: $KERNEL_SRC";
			if [ ! -f "$KERNEL_SRC" ]; then
				wget $KERNEL_URL;
			fi;
			if [ $? -ne 0 ]; then 
				echo "*** WARNING ***:  Can't download kernel source \"$KERNEL_URL\". Please, verify server and client files after installation.";
			fi;
		fi;
	done < $LDV_ONLINE_CONF;
	echo "LDV node installation successfully finished.";
	echo "------------ to start cleint use: -------------";
	echo "$LDV_HOME/bin/ldv_client";
	echo "Then you can see log file: $LDV_ONLINE_HOME/logs/client.log";
fi


