LDV_HOME=`readlink -f \`dirname $0\`/../../`;
LDV_INSTALL_TYPE=server
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
	# read wwwdocs from server.conf and copy new version
        while read LINE; do
                if [ -n "`echo $LINE | grep wwwdocs=`" ]; then
                        wwwdocs=`echo "$LINE" | grep '^wwwdocs=' |sed 's/wwwdocs=//g'`;
                fi; 
        done < $LDV_ONLINE_CONF;
	if [ ! -n "$wwwdocs" ]; then
		echo "ERROR: Can't read wwwdocs param from \"$LDV_ONLINE_CONF\" file. Fix config file and try again."
	fi;
	if [ ! -w "$wwwdocs" ]; then
		if [ ! -d "$wwwdocs/ldv" -o ! -w "$wwwdocs/ldv" -o ! -f "$wwwdocs/ldv_online_service.php" -o ! -w "$wwwdocs/ldv_online_service.php" ]; then
			echo "ERROR: You have no write access to \"$wwwdocs\". Run script under root or create dir \"$wwwdocs/ldv\" and file \"$wwwdocs/ldv_online_service.php\" with write access privileges for current user.";
			exit 1;
		fi;
	fi;
	# update www docs
	cp -r $LDV_ONLINE_HOME/ldvwface/* $wwwdocs/;
	if [ $? -ne 0 ]; then
		echo "Can't copy www docs from \"$LDV_ONLINE_HOME/ldvwface/*\" to \"$wwwdocs\".";
		echo "Remove configuration.";
		rm $LDV_ONLINE_CONF;
		exit 1;
	fi;
	# insert config init function to ldv_online_service script
	sed -i -e "s|^CONFIG_PLACE$|WSInit('$LDV_ONLINE_CONF');|g" $wwwdocs/ldv_online_service.php;
else
	echo "First installation mode.";
	# read and test all needed options
	for arg in $@; do
	        case $arg in
			--wwwdocs=*)
	                       	wwwdocs=`echo $arg | sed 's/--wwwdocs=//g'`;
	                       	if [ ! -n "$wwwdocs" ]; then
	                       	        echo "ERROR: Parameter \"--wwwdocs\" - is null. Setup it.";
	                       	        exit 1;
	                       	fi;
			;;
			--tempdir=*)
	                       	tempdir=`echo $arg | sed 's/--tempdir=//g'`;
	                       	if [ ! -n "$tempdir" ]; then
	                       	        echo "ERROR: Parameter \"--tempdir\" - is null. Setup it.";
	                       	        exit 1;
	                       	fi;
	               	;;
			--dbuser=*)
				dbuser=`echo $arg | sed 's/--dbuser=//g'` 
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
	if [ ! -n "$tempdir" ]; then
		echo "Temp dir is null. Please, set up --tempdir parameter.";
		exit 1;
	fi;
	if [ ! -n "$wwwdocs" ]; then
		echo "WWW docs is null. Please, set up --wwwdocs parameter.";
		exit 1;
	fi;
	
	if [ ! -w "$wwwdocs" ]; then
		if [ ! -d "$wwwdocs/ldv" -o ! -w "$wwwdocs/ldv" -o ! -f "$wwwdocs/ldv_online_service.php" -o ! -w "$wwwdocs/ldv_online_service.php" ]; then
			echo "ERROR: You have no write access to \"$wwwdocs\". Run script under root or create dir \"$wwwdocs/ldv\" and file \"$wwwdocs/ldv_online_service.php\" with write access privileges for current user.";
			exit 1;
		fi;
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


	if [ ! -d "$tempdir" ]; then
		echo "Temp dir does't exists."; 
		echo "Try to create it...";
		mkdir -p $tempdir/run && mkdir -p $tempdir/logs;
		if [ $? -ne 0 ]; then
			echo "Can't create temp dir \"$tempdir\".";
			exit 1;
		fi;
		echo "Temp dir successfully created.";
	fi; 
	tempdir=`readlink -f $tempdir`;
	if [ $? -ne 0 ]; then
		echo "ERROR: Can't read abs path for temp dir: \"$tempdir\".";
		exit 1;
	fi;

	if [ ! -d "$wwwdocs" ]; then
		echo "WWW docs dir does't exists."; 
		echo "Try to create it...";
		mkdir -p $wwwdocs;
		if [ $? -ne 0 ]; then
			echo "Can't create www docs dir \"$wwwdocs\".";
			exit 1;
		fi;
		echo "WWW docs dir successfully created.";
	fi; 
	wwwdocs=`readlink -f $wwwdocs`;
	if [ $? -ne 0 ]; then
		echo "ERROR: Can't read abs path for temp dir: \"$wwwdocs\".";
		exit 1;
	fi;

	# and now copy configureation
	cp $LDV_ONLINE_SAMPLE_CONF $LDV_ONLINE_CONF;
	echo "cp $LDV_ONLINE_SAMPLE_CONF $LDV_ONLINE_CONF;";
	if [ $? -ne 0 ]; then
		echo "ERROR: Can't copy \"$LDV_ONLINE_SAMPLE_CONF\" to \"$LDV_ONLINE_CONF\".";
		exit 1;
	fi;
	# and setup new parameters
	sed -i -e "s|^WorkDir=.*$|WorkDir=$tempdir|g" $LDV_ONLINE_CONF;
	sed -i -e "s|^ModelsDBPath=.*$|ModelsDBPath=$LDV_HOME/kernel-rules/model-db.xml|g" $LDV_ONLINE_CONF;
	sed -i -e "s|^RulesDBPath=.*$|RulesDBPath=$LDV_HOME/kernel-rules/rules/DRVRULES_en.trl|g" $LDV_ONLINE_CONF;
	sed -i -e "s|^ErrorTraceVisualizer=.*$|ErrorTraceVisualizer=$LDV_HOME/bin/error-trace-visualizer.pl|g" $LDV_ONLINE_CONF;
	sed -i -e "s|^WSTempDir=.*$|WSTempDir=$tempdir|g" $LDV_ONLINE_CONF;
	sed -i -e "s|^wwwdocs=.*$|wwwdocs=$wwwdocs|g" $LDV_ONLINE_CONF;
	
	# database options
	#if [ ! -n "$dbuser" ]; then dbuser=statsuserd; fi;
	#if [ ! -n "$dbpass" ]; then dbpass=statspass; fi;
	#if [ ! -n "$dbhost" ]; then dbhost=localhost; fi;
	#if [ ! -n "$dbname" ]; then dbname=statsdb; fi;

	sed -i -e "s|^StatsDBUser=.*$|StatsDBUser=$dbuser|g" $LDV_ONLINE_CONF;
	sed -i -e "s|^StatsDBPass=.*$|StatsDBPass=$dbpass|g" $LDV_ONLINE_CONF;
	sed -i -e "s|^StatsDBHost=.*$|StatsDBHost=$dbhost|g" $LDV_ONLINE_CONF;
	sed -i -e "s|^StatsDBName=.*$|StatsDBName=$dbname|g" $LDV_ONLINE_CONF;

	# install www docs
	cp -r $LDV_ONLINE_HOME/ldvwface/* $wwwdocs/;
	if [ $? -ne 0 ]; then
		echo "Can't copy www docs from \"$LDV_ONLINE_HOME/ldvwface/*\" to \"$wwwdocs\".";
		echo "Remove configuration.";
		rm $LDV_ONLINE_CONF;
		exit 1;
	fi;
	# insert config init function to ldv_online_service script
	sed -i -e "s|^CONFIG_PLACE$|WSInit('$LDV_ONLINE_CONF');|g" $wwwdocs/ldv_online_service.php;
	echo "Server installation successfully finished.";
fi


