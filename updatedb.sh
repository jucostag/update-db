#!/bin/bash

# Author: Juliana Gonçalves da Costa Soares <juliana.goncosta@gmail.com>
# Author URI: https://github.com/jucostag

# All MAKE_* variables are comming from the enviromnent.

DATE=$(which date)

# SOME FUNCTIONS TO ORGANIZE
##################################################################################################

structureAndData() {
    while read table
        do echo "Copying ${table}"
        table=${table/$'\r'/}
        result_file="${table}.sql"
        mysqldump -u$MAKE_PRODUCTION_DB_USER -p$MAKE_PRODUCTION_DB_PASS -h $MAKE_PRODUCTION_DB_HOST --skip-lock-tables $MAKE_PRODUCTION_DB_NAME $table > $TABLES_TO_INSERT_PATH/$result_file
        wait
    done < $TABLES_LIST_PATH/.tablesdata
    wait
}

structureOnly() {
    while read table 
        do echo "Copying ${table}"
        table=${table/$'\r'/}
        result_file="${table}.sql"
        mysqldump -u$MAKE_PRODUCTION_DB_USER -p$MAKE_PRODUCTION_DB_PASS -h $MAKE_PRODUCTION_DB_HOST --no-data=true --skip-lock-tables $MAKE_PRODUCTION_DB_NAME $table > $TABLES_TO_INSERT_PATH/$result_file
        wait
    done < $TABLES_LIST_PATH/.tablesstructure
    wait
}

# STARTING UPDATE PROCESS
##################################################################################################

current_date=$(date '+%d%m%Y%H%M%S')
backup_path="${TABLES_BACKUP_PATH}/backup_${MAKE_LOCAL_DB_NAME}_$current_date.sql"

echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - First, we need to clean your backup directories..."
rm -r $TABLES_TO_INSERT_PATH/*.sql
rm -r $TABLES_BACKUP_PATH/*.sql

echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - Updating your local $MAKE_LOCAL_DB_NAME database"
echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - Saving a backup from your current database in $TABLES_BACKUP_PATH"

mysqldump -u$MAKE_LOCAL_DB_USER -p$MAKE_LOCAL_DB_PASS -hmysql --verbose $MAKE_LOCAL_DB_NAME > $backup_path

# THIS IS PRODUCTION DATA, DON'T CHANGE ANYTHING! WE'RE JUST DUMPING A COPY.
##################################################################################################

echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - Exporting STRUCTURE ONLY from log tables of production database in $TABLES_TO_INSERT_PATH"

structureOnly

echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - Exporting STRUCTURE AND DATA from production database in $TABLES_TO_INSERT_PATH"

structureAndData

##################################################################################################
# END OF PRODUCTION DATA DUMPING


# NOW, WE'RE GONNA PREPARE YOUR LOCAL DATABASE TO RECEIVE THE FRESH DATA :)
##################################################################################################
echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - Preparing your local database to receive the fresh data extracted from production..." 
cd $TABLES_TO_INSERT_PATH

mysql -u$MAKE_LOCAL_DB_USER -p$MAKE_LOCAL_DB_PASS --verbose -e "DROP DATABASE $MAKE_LOCAL_DB_NAME;"
wait
mysql -u$MAKE_LOCAL_DB_USER -p$MAKE_LOCAL_DB_PASS --verbose -e "CREATE DATABASE $MAKE_LOCAL_DB_NAME CHARACTER SET $MAKE_LOCAL_DB_CHARSET COLLATE $MAKE_LOCAL_DB_COLLATE;"
wait

# IMPORTING THE UPDATED DATA EXTRACTED BEFORE FROM PRODUCTION INTO YOUR RECENTLY CREATED DATABASE
##################################################################################################

echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - Importing the new data..." 

for file in *.sql
    do  mysql -u$MAKE_LOCAL_DB_USER -p$MAKE_LOCAL_DB_PASS --verbose $MAKE_LOCAL_DB_NAME < $file
    wait
done

# THEN WE CLEAN UP THE INSERT DIRECTORY, CAUSE WE DON'T NEED THE SQL FILES ANYMORE, ONCE THEY WERE IMPORTED
##################################################################################################

echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - Cleaning your $TABLES_TO_INSERT_PATH directory now..."
rm -r $TABLES_TO_INSERT_PATH/*.sql

echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - Success! Your local database $MAKE_LOCAL_DB_NAME is up-to-date!"
echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - Just to remind you, we made a backup of your $MAKE_LOCAL_DB_NAME database before, so you can recover data if you need to :)"
