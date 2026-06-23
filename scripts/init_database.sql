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
