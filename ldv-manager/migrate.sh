LDV_HOME=`readlink -f \`dirname $0\`/../`;
LDV_MANAGER_HOME=$LDV_HOME/ldv-manager
LDV_RESULTS_SCHEMA_FILENAME=results_schema.sql
LDV_RESULTS_SCHEMA=$LDV_MANAGER_HOME/$LDV_RESULTS_SCHEMA_FILENAME
LDV_MANAGER_MIGRATES_DIR=$LDV_MANAGER_HOME/migrates

DATABASE=mysql

#
# TODO: Fix ldv-online - fro pattern insert (when it creates db)
#
DBNAME=${DBNAME:-};
DBUSER=${DBUSER:-};
DBPASS=${DBPASS:-};
DBHOST=${DBHOST:-localhost};
DBPORT=${DBPORT:-3306};

if [ ! -n "$DBUSER" ]; then 
	echo "ERROR: Please, specify database user throug environment variable DBUSER !";
	exit 1;
fi;
if [ ! -n "$DBNAME" ]; then 
	echo "ERROR: Please, specify database name throug environment variable DBNAME !";
	exit 1;
fi;

echo "--------------- MIGRATION OPTIONS ----------------"
echo " 1. Directory with migration scripts.. \"$LDV_MANAGER_MIGRATES_DIR\"";
echo " 3. Database user........,............ \"$DBUSER\"";
if [ -n "$DBPASS" ]; then
	echo " 4. Database password................. \"$DBPASS\"";
else
	echo " 4. Database password................. \"empty\"";
fi;
echo " 5. Database name..................... \"$DBNAME\"";
echo " 6. Database host..................... \"$DBHOST\"";
echo " 6. Database port..................... \"$DBPORT\"";
echo "--------------------------------------------------"

SDBUSER="-u$DBUSER";
if [ -n "$DBPASS" ]; then SDBPASS="-p$DBPASS"; fi;
SDBHOST="-h$DBHOST";
SDBPORT="-P$DBPORT";
SDBNAME=$DBNAME;
DBRUN="$DATABASE $SDBUSER $SDBPASS $SDBHOST $SDBPORT $SDBNAME";

#
# Test database connection
#
echo "exit" | $DBRUN;
if [ $? -ne 0 ]; then
	echo "ERROR: Database connection error.";
	exit 1;
fi;

#
# If database tables not exists - create last result_schema,sql
#
ISNULL=`echo "show tables" | $DBRUN`;
if [ ! -n "$ISNULL" ]; then 
	echo "You have empty database.";
	$DBRUN < $LDV_RESULTS_SCHEMA;
	if [ $? -ne 0 ]; then
		echo "ERROR: Can't create database tables from \"$LDV_RESULTS_SCHEMA\".";
		exit 1;
	fi;
	echo "Database tables successfully created !";
fi;

#
# Is it 0 version of db (no db_properties and processes)
#
ISZERO=`echo "show tables" | $DBRUN | grep db_properties;`
if [ ! -n "$ISZERO" ]; then
	echo "Your database have zero version.";
	DB_CURRENT_VERSION=0;
else
	#
	# Connect to database and get version
	#
	DB_CURRENT_VERSION=`echo "select value from db_properties where name='version'" | $DBRUN | grep '[0-9][0-9]*';`;
	if [ $? -ne 0 ]; then
		echo "ERROR: Database error.";
		exit 1;
	fi;
	echo "Your database version: $DB_CURRENT_VERSION";
fi;
	
#
# Update MySQL database
# 
if [ -d "$LDV_MANAGER_MIGRATES_DIR" ]; then
        let gnumber=$DB_CURRENT_VERSION+1;
        for i in `ls $LDV_MANAGER_MIGRATES_DIR`; do
                if [ -d "$LDV_MANAGER_MIGRATES_DIR/$gnumber" ]; then
                        echo "Start migration: from version $DB_CURRENT_VERSION to : \"$LDV_MANAGER_MIGRATES_DIR/$gnumber\"";
			for i in `find $LDV_MANAGER_MIGRATES_DIR/$gnumber -maxdepth 1 -type f -name "*.sql"`; do
				echo "Apply updates from SQL-script: \"$i\".";
				$DBRUN <$i;
				if [ $? -ne 0 ]; then
					echo "ERROR: Can't apply updates from SQL-script \"$i\"";
					exit 1;
				fi;
				echo "Update database version to: \"$gnumber\".";
				$DBRUN -e "UPDATE db_properties SET value='$gnumber' WHERE name='version';";
				if [ $? -ne 0 ]; then
					echo "ERROR: Can't update database version";
					exit 1;
				fi;
				echo "Database successfully updated to $gnumber version.";
			done;
                else
                        break;
                fi  
                let gnumber=$gnumber+1;
        done;
fi;
