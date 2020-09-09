#!/bin/bash

# Author: Juliana Gonçalves da Costa Soares <juliana.goncosta@gmail.com>
# Author URI: https://github.com/jucostag

# All MAKE_* variables are comming from the enviromnent.

DATE=$(which date)

# SOME FUNCTIONS TO ORGANIZE
##################################################################################################

getTables() {
	while read table
		do table=${table/$'\r'/}
		echo "Copying ${table}"
		result_file="${table}.sql"
		mysqldump -u$MAKE_PRODUCTION_DB_USER -p$MAKE_PRODUCTION_DB_PASS -h $MAKE_PRODUCTION_DB_HOST --verbose --lock-tables=false $MAKE_PRODUCTION_DB_NAME $table > $TABLES_TO_INSERT_PATH/$result_file
		wait
	done < $TABLES_LIST_PATH/.tableslist
	wait
}

backupTables() {    
	while read table; do 
		table=${table/$'\r'/}
		echo "Saving a copy of your local ${table}"
		result_file="tablebkp_${table}_${current_date}.sql"
		mysqldump -u$MAKE_LOCAL_DB_USER -p$MAKE_LOCAL_DB_PASS --verbose $MAKE_LOCAL_DB_NAME $table > $TABLES_BACKUP_PATH/$result_file
		wait
	done < $TABLES_LIST_PATH/.tableslist
}

dropTables() {
	while read table; do
		mysql -u$MAKE_LOCAL_DB_USER -p$MAKE_LOCAL_DB_PASS --verbose -e "DROP TABLE $MAKE_LOCAL_DB_NAME.$table;"
		wait
	done < $TABLES_LIST_PATH/.tableslist
}

# CHECKING IF .tableslist exists to start the process
##################################################################################################

TABLESLIST=$TABLES_LIST_PATH/.tableslist
if [ -f "$TABLESLIST" ]; then

	# STARTING UPDATE PROCESS
	##################################################################################################

	current_date=$(date '+%d%m%Y%H%M%S')
	insert_path="/insert"

	echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - First, we need to clean your backup directories..."
	rm -r $TABLES_TO_INSERT_PATH/*.sql
	rm -r $TABLES_BACKUP_PATH/tablebkp_*.sql

	echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - Updating your local $MAKE_LOCAL_DB_NAME database"

	echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - Saving a backup from your current database in $TABLES_BACKUP_PATH"

	backupTables

	# THIS IS PRODUCTION DATA, DON'T CHANGE ANYTHING! WE'RE JUST DUMPING A COPY.
	##################################################################################################

	echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - Exporting STRUCTURE AND DATA from log tables of production database in $TABLES_TO_INSERT_PATH"

	getTables

	##################################################################################################
	# END OF PRODUCTION DATA DUMPING


	# NOW, WE'RE GONNA PREPARE YOUR LOCAL DATABASE TO RECEIVE THE FRESH DATA :)
	##################################################################################################

	echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - Preparing your local database to receive the fresh data extracted from production..." 

	dropTables

	cd $TABLES_TO_INSERT_PATH

	# IMPORTING THE UPDATED DATA EXTRACTED BEFORE FROM PRODUCTION INTO YOUR RECENTLY CREATED DATABASE
	##################################################################################################

	echo "Importing the new data..." 

	for file in *.sql
	    do  mysql -u$MAKE_LOCAL_DB_USER -p$MAKE_LOCAL_DB_PASS --verbose $MAKE_LOCAL_DB_NAME < $file
	    wait
	done

	# THEN WE CLEAN UP THE INSERT DIRECTORY, CAUSE WE DON'T NEED THE SQL FILES ANYMORE, ONCE THEY WERE IMPORTED
	##################################################################################################

	echo "Cleaning your $TABLES_TO_INSERT_PATH directory now..."
	rm -r $TABLES_TO_INSERT_PATH/*.sql

	echo "Success! Your tables are now up-to-date!"
	echo "Just to remind you, we made a backup of these tables before, so you can recover data if you need to :)"

else
	echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - Create a file named .tableslist containing tables to update in $TABLES_LIST_PATH"
    exit 1
fi
