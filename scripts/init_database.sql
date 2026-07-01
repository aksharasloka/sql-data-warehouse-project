/*
===============================================================
DDL Script: Initialize Database and Schemas
===============================================================
Script Purpose:
    This script creates the 'DataWarehouse' database and the
    three schemas: bronze, silver, and gold.
    Run this script once to set up the initial database structure.

    Warning: This script drops and recreates the database.
    All existing data will be lost.
===============================================================
*/

-- Drop and recreate database
DROP DATABASE IF EXISTS "DataWarehouse";
CREATE DATABASE "DataWarehouse";

-- Connect to the database
\c "DataWarehouse";

-- Drop and recreate schemas
DROP SCHEMA IF EXISTS bronze CASCADE;
DROP SCHEMA IF EXISTS silver CASCADE;
DROP SCHEMA IF EXISTS gold CASCADE;

CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;
