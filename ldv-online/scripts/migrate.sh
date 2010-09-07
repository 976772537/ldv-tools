LDV_HOME=`readlink -f \`dirname $0\`/../../`;
LDV_INSTALL_TYPE=server
LDV_ONLINE_HOME=$LDV_HOME/ldv-online
LDV_MANAGER_HOME=$LDV_HOME/ldv-manager
#LDV_MANAGER_MIGRATES_DIR=$LDV_MANAGER_HOME/migrates
LDV_ONLINE_LIB_DIR=$LDV_ONLINE_HOME/lib
LDV_ONLINE_H2DB=$LDV_ONLINE_LIB_DIR/h2-1.2.136.jar
LDV_ONLINE_CONF_DIR=$LDV_ONLINE_HOME/conf
LDV_ONLINE_CONF=$LDV_ONLINE_CONF_DIR/$LDV_INSTALL_TYPE.conf

#
# Is client.conf and server.conf already exists then
# script run in update mode
#
if [ -f $LDV_ONLINE_CONF ]; then
	# read all parameters from server.conf and copy new version
	echo "Read config file: \"$LDV_ONLINE_CONF\".";
        while read LINE; do
		if [ -n "`echo $LINE | grep StatsDBUser=`" ]; then
                        StatsDBUser=`echo "$LINE" | sed 's/StatsDBUser=//g'`;
		elif [ -n "`echo $LINE | grep InnerDBConnectOptions=`" ]; then
                        InnerDBConnectOptions=`echo "$LINE" | sed 's/InnerDBConnectOptions=//g'`;
		elif [ -n "`echo $LINE | grep WSTempDir=`" ]; then
                        WSTempDir=`echo "$LINE" | sed 's/WSTempDir=//g'`;
		elif [ -n "`echo $LINE | grep InnerDBHost=`" ]; then
                        InnerDBHost=`echo "$LINE" | sed 's/InnerDBHost=//g'`;
		elif [ -n "`echo $LINE | grep InnerDBUser=`" ]; then
                        InnerDBUser=`echo "$LINE" | sed 's/InnerDBUser=//g'`;
		elif [ -n "`echo $LINE | grep InnerDBPass=`" ]; then
                        InnerDBPass=`echo "$LINE" | sed 's/InnerDBPass=//g'`;
		elif [ -n "`echo $LINE | grep StatsDBPass=`" ]; then
                        StatsDBPass=`echo "$LINE" | sed 's/StatsDBPass=//g'`;
		elif [ -n "`echo $LINE | grep StatsDBName=`" ]; then
                        StatsDBName=`echo "$LINE" | sed 's/StatsDBName=//g'`;
		elif [ -n "`echo $LINE | grep StatsDBHost=`" ]; then
                        StatsDBHost=`echo "$LINE" | sed 's/StatsDBHost=//g'`;
		elif [ -n "`echo $LINE | grep StatsDBMigratesDir=`" ]; then
                        LDV_MANAGER_MIGRATES_DIR=`echo "$LINE" | sed 's/StatsDBMigratesDir=//g'`;
		elif [ -n "`echo $LINE | grep StatsDBUpdateVersion=`" ]; then
                        let number=`echo "$LINE" | sed 's/StatsDBUpdateVersion=//g'`;
		elif [ -n "`echo $LINE | grep InnerDBMigratesDir=`" ]; then
                        LDV_ONLINE_MIGRATES_DIR=`echo "$LINE" | sed 's/InnerDBMigratesDir=//g'`;
		elif [ -n "`echo $LINE | grep InnerDBUpdateVersion=`" ]; then
                        let inumber=`echo "$LINE" | sed 's/InnerDBUpdateVersion=//g'`;
                fi; 
        done < $LDV_ONLINE_CONF;

	echo "------------ SERVER CONFIG OPTIONS -------------"
	echo " 1. WSTempDir.............. \"$WSTempDir\"";
	echo "    Directory for H2 database files."
	echo " 2. InnerDBConnectOptions.. \"$InnerDBConnectOptions\"";
	echo "    Connection options for H2 database.";
	echo " 3. StatsDBUpdateVersion... \"$number\"";
	echo "    MySQL database current update version.";
	echo " 4. StatsDBMigratesDir..... \"$LDV_MANAGER_MIGRATES_DIR\"";
	echo " 5. InnerDBUpdateVersion... \"$inumber\"";
	echo " 6. InnerDBMigratesDir..... \"$LDV_ONLINE_MIGRATES_DIR\"";
	echo " 7. StatsDBUser............ \"$StatsDBUser\"";
	echo " 8. StatsDBUser............ \"$StatsDBUser\"";
	echo " 9. StatsDBPass............ \"$StatsDBPass\"";
	echo "10. StatsDBName............ \"$StatsDBName\"";
	echo "11. StatsDBHost............ \"$StatsDBHost\"";
	echo "12. InnerDBHost............ \"$InnerDBHost\"";
	echo "13. InnerDBUser............ \"$InnerDBUser\"";
	echo "14. InnerDBPass............ \"$InnerDBPass\"";
	echo "------------------------------------------------"

	#
	# test MySQL connection
	#
	echo "exit" | mysql -u$StatsDBUser -p$StatsDBPass -h$StatsDBHost $StatsDBName;
	if [ $? -ne 0 ]; then
		echo "ERROR: Can't connect to database.";
		exit 1;
	fi;

	#
	# Update MySQL database
	# 
	if [ -d "$LDV_MANAGER_MIGRATES_DIR" ]; then
	        let gnumber=$number+1;
	        for i in `ls $LDV_MANAGER_MIGRATES_DIR`; do
	                if [ -d "$LDV_MANAGER_MIGRATES_DIR/$gnumber" ]; then
	                        echo "Start migration: version $number from: \"$LDV_MANAGER_MIGRATES_DIR/$gnumber\"";
				for i in `find $LDV_MANAGER_MIGRATES_DIR/$gnumber -maxdepth 1 -type f -name *.sql`; do
					echo "Apply updates from SQL-script: \"$i\".";
					mysql -u$StatsDBUser -p$StatsDBPass -h$StatsDBHost $StatsDBName <$i;
					if [ $? -ne 0 ]; then
						echo "ERROR: Can't apply updates from SQL-script \"$i\"";
						exit 1;
					fi;
				done;
				#set new version to config file...
				sed -i -e "s|^StatsDBUpdateVersion=.*$|StatsDBUpdateVersion=$gnumber|g" $LDV_ONLINE_CONF;
	                        echo "Ok."
	                else
	                        break;
	                fi  
	                let gnumber=$gnumber+1;
	        done;
	fi;


	#
	# Test H2 connection
	#
	echo "exit" | java -cp $LDV_ONLINE_H2DB org.h2.tools.Shell -url "jdbc:h2:tcp://$InnerDBHost$WSTempDir/db$InnerDBConnectOptions" -user $InnerDBUser -password $InnerDBPass;
	if [ $? -ne 0 ]; then
		echo "ERROR: Can't connect to H2 database.";
		exit 1;
	fi;


	#
	# Update H2 database
	#
	if [ -d "$LDV_ONLINE_MIGRATES_DIR" ]; then
	        let gnumber=$inumber+1;
	        for i in `ls $LDV_ONLINE_MIGRATES_DIR`; do
	                if [ -d "$LDV_ONLINE_MIGRATES_DIR/$gnumber" ]; then
	                        echo "Start migration: version $inumber from: \"$LDV_ONLINE_MIGRATES_DIR/$gnumber\"";
				for i in `find $LDV_ONLINE_MIGRATES_DIR/$gnumber -maxdepth 1 -type f -name *.sql`; do
					echo "Apply updates from SQL-script: \"$i\".";
					java -cp $LDV_ONLINE_H2DB org.h2.tools.Shell -url "jdbc:h2:tcp://$InnerDBHost$WSTempDir/db$InnerDBConnectOptions" -user $InnerDBUser -password $InnerDBPass <$i;
					if [ $? -ne 0 ]; then
						echo "ERROR: Can't apply updates from SQL-script \"$i\"";
						exit 1;
					fi;
				done;
				#set new version to config file...
				sed -i -e "s|^InnerStatsDBUpdateVersion=.*$|InnerDBUpdateVersion=$gnumber|g" $LDV_ONLINE_CONF;
	                        echo "Ok."
	                else
	                        break;
	                fi  
	                let gnumber=$gnumber+1;
	        done;
	fi;


else
	echo "ERROR: Can't find \"$LDV_ONLINE_CONF\" file.";
fi;
