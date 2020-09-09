# update-db scripts

Two scripts to automate local databases with production data. The updatedb.sh script replace your entire local database, and updatetables.sh updates just a few tables of your choice.

Create the following enviroment variables and add the path to download the sql files and backups, and database credentials for your local and production / homolog / dev mysql that contains the updated data.

TABLES_LIST_PATH=
TABLES_TO_INSERT_PATH=
TABLES_BACKUP_PATH=

MAKE_PRODUCTION_DB_USER
MAKE_PRODUCTION_DB_PASS
MAKE_PRODUCTION_DB_HOST
MAKE_PRODUCTION_DB_NAME

MAKE_LOCAL_DB_NAME
MAKE_LOCAL_DB_USER
MAKE_LOCAL_DB_PASS
MAKE_LOCAL_DB_CHARSET
MAKE_LOCAL_DB_COLLATE


Then create, on the $TABLES_LIST_PATH, create these files:

For updatetables:
.tableslist - List of tables that will be updated in your local database.

For updatedb:
.tablesstructure - List of tables that you want just the structure. It's a good option for large tables like logs for example.

.tablesdata - List of tables that you be updated completely with structure and data.