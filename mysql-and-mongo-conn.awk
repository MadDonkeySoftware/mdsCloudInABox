$1 == "MONGO_INITDB_ROOT_PASSWORD:" { $1 = "      " $1; $2 = "'" MONGO_PASSWORD "'"; }
$1 == "MYSQL_ROOT_PASSWORD:" { $1 = "      " $1; $2 = "'" MYSQL_ROOT_PASSWORD "'"; }
$1 == "MYSQL_PASSWORD:" { $1 = "      " $1; $2 = "'" MYSQL_USER_PASSWORD "'"; }
$1 == "FN_DB_URL:" { $1 = "      " $1; $2 = "'" FN_SERVER_DB_URL "'"; }
$1 == "MDS_FN_MONGO_URL:" { $1 = "      " $1; $2 = "'" FN_MONGO_URL "'"; }
$1 == "MDS_IDENTITY_DB_URL:" { $1 = "      " $1; $2 = "'" IDENTITY_DB_URL "'" }
$1 == "FN_SM_DB_URL:" { $1 = "      " $1; $2 = "'" FN_SM_DB_URL "'" }
1 # Prints the current line (modified)