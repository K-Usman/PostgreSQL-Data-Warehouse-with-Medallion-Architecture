/*
================================================================
Create schemas
================================================================

Purpose: This script creates three new schemas 'bronze', 'silver' and 'gold' within the data warehouse. The data warehouse
'salesdwh' has already been created from the pgadmin and this script should be run inside that database.
*/

CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

