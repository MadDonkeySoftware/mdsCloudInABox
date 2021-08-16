$1 == "MDS_SYS_PASSWORD:" { $1 = "      " $1; $2 = "'" MDS_USER_PASS "'" }
$1 == "MDS_SM_SYS_PASSWORD:" { $1 = "      " $1; $2 = "'" MDS_USER_PASS "'" }
$1 == "MDS_QS_SYS_PASSWORD:" { $1 = "      " $1; $2 = "'" MDS_USER_PASS "'" }
$1 == "MDS_FN_SYS_PASSWORD:" { $1 = "      " $1; $2 = "'" MDS_USER_PASS "'" }
1 # Prints the current line (modified)