-- ============================================================
-- USERS AND ROLES
-- ============================================================

USE [master]
GO

-- Creating Logins (at server level)
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'f1_admin_user')
BEGIN
    CREATE LOGIN [f1_admin_user] WITH PASSWORD = 'f1_admin_user', 
        DEFAULT_DATABASE = [Formula1],
        CHECK_POLICY = OFF,
        CHECK_EXPIRATION = OFF;
    PRINT 'Login f1_admin_user created.'
END
GO

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'f1_analyst_user')
BEGIN
    CREATE LOGIN [f1_analyst_user] WITH PASSWORD = 'f1_analyst_user', 
        DEFAULT_DATABASE = [Formula1],
        CHECK_POLICY = OFF,
        CHECK_EXPIRATION = OFF;
    PRINT 'Login f1_analyst_user created.'
END
GO

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'f1_dataentry_user')
BEGIN
    CREATE LOGIN [f1_dataentry_user] WITH PASSWORD = 'f1_dataentry_user', 
        DEFAULT_DATABASE = [Formula1],
        CHECK_POLICY = OFF,
        CHECK_EXPIRATION = OFF;
    PRINT 'Login f1_dataentry_user created.'
END
GO

USE [Formula1]
GO

-- Creating Users in the database
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'f1_admin_user')
BEGIN
    CREATE USER [f1_admin_user] FOR LOGIN [f1_admin_user];
    PRINT 'User f1_admin_user created in Formula1.'
END
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'f1_analyst_user')
BEGIN
    CREATE USER [f1_analyst_user] FOR LOGIN [f1_analyst_user];
    PRINT 'User f1_analyst_user created in Formula1.'
END
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'f1_dataentry_user')
BEGIN
    CREATE USER [f1_dataentry_user] FOR LOGIN [f1_dataentry_user];
    PRINT 'User f1_dataentry_user created in Formula1.'
END
GO

-- Creating Roles
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'db_f1_admin' AND type = 'R')
BEGIN
    CREATE ROLE [db_f1_admin];
    PRINT 'Role db_f1_admin created.'
END
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'db_f1_analyst' AND type = 'R')
BEGIN
    CREATE ROLE [db_f1_analyst];
    PRINT 'Role db_f1_analyst created.'
END
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'db_f1_dataentry' AND type = 'R')
BEGIN
    CREATE ROLE [db_f1_dataentry];
    PRINT 'Role db_f1_dataentry created.'
END
GO

-- ============================================================
-- ASSIGNING PERMISSIONS TO ROLES
-- ============================================================

-- ADMIN - Full control
GRANT CONTROL ON DATABASE:: Formula1 TO [db_f1_admin];
PRINT 'CONTROL permissions granted to db_f1_admin role.'
GO

-- ANALYST - SELECT on all tables and views + EXECUTE on analysis procedures
GRANT SELECT ON SCHEMA:: dbo TO [db_f1_analyst];
PRINT 'SELECT permissions granted to db_f1_analyst role.'

-- Analysis procedures for Analyst
GRANT EXECUTE ON [dbo].[sp_CompareDrivers] TO [db_f1_analyst];
GRANT EXECUTE ON [dbo].[sp_CompareDriversAdvanced] TO [db_f1_analyst];
GRANT EXECUTE ON [dbo].[sp_AnalyzeDriverSeasonPerformance] TO [db_f1_analyst];
GRANT EXECUTE ON [dbo].[sp_AnalyzeOptimalPitStrategy] TO [db_f1_analyst];
GRANT EXECUTE ON [dbo].[sp_AnalyzeTeamReliability] TO [db_f1_analyst];
GRANT EXECUTE ON [dbo].[sp_CalculateChampionshipGaps] TO [db_f1_analyst];
GRANT EXECUTE ON [dbo].[sp_GenerateSeasonStandingsReport] TO [db_f1_analyst];
GRANT EXECUTE ON [dbo].[sp_DriverContracts_GetByDriver] TO [db_f1_analyst];
GRANT EXECUTE ON [dbo].[sp_DriverContracts_GetByTeam] TO [db_f1_analyst];
-- GetAll procedures for Analyst
GRANT EXECUTE ON [dbo].[sp_Driver_GetAll] TO [db_f1_analyst];
GRANT EXECUTE ON [dbo].[sp_Driver_GetByName] TO [db_f1_analyst];
GRANT EXECUTE ON [dbo].[sp_Team_GetAll] TO [db_f1_analyst];
GRANT EXECUTE ON [dbo].[sp_Team_GetByName] TO [db_f1_analyst];
GRANT EXECUTE ON [dbo].[sp_Circuit_GetAll] TO [db_f1_analyst];
GRANT EXECUTE ON [dbo].[sp_Circuit_GetByName] TO [db_f1_analyst];
GRANT EXECUTE ON [dbo].[sp_Race_GetByYear] TO [db_f1_analyst];
GRANT EXECUTE ON [dbo].[sp_Race_GetByName] TO [db_f1_analyst];
GRANT EXECUTE ON [dbo].[sp_Nationality_GetAll] TO [db_f1_analyst];
GRANT EXECUTE ON [dbo].[sp_Country_GetAll] TO [db_f1_analyst];
GRANT EXECUTE ON [dbo].[sp_City_GetAll] TO [db_f1_analyst];
GRANT EXECUTE ON [dbo].[sp_Continents_GetAll] TO [db_f1_analyst];
GRANT EXECUTE ON [dbo].[sp_Seasons_GetAll] TO [db_f1_analyst];
GRANT EXECUTE ON [dbo].[sp_Status_GetAll] TO [db_f1_analyst];
-- New query procedures for Analyst
GRANT EXECUTE ON [dbo].[sp_RaceResult_GetByRace] TO [db_f1_analyst];
GRANT EXECUTE ON [dbo].[sp_Qualifying_GetByRace] TO [db_f1_analyst];
GRANT EXECUTE ON [dbo].[sp_PitStop_GetByRace] TO [db_f1_analyst];
PRINT 'EXECUTE permissions granted to db_f1_analyst role on analysis procedures.'
GO

-- DATA ENTRY - EXECUTE only on CRUD procedures (no direct table access)
-- Driver procedures
GRANT EXECUTE ON [dbo].[sp_Driver_GetAll] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Driver_GetByName] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Driver_Insert] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Driver_Update] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Driver_Delete] TO [db_f1_dataentry];
-- Team procedures
GRANT EXECUTE ON [dbo].[sp_Team_GetAll] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Team_GetByName] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Team_Insert] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Team_Update] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Team_Delete] TO [db_f1_dataentry];
-- Circuit procedures
GRANT EXECUTE ON [dbo].[sp_Circuit_GetAll] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Circuit_GetByName] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Circuit_Insert] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Circuit_Delete] TO [db_f1_dataentry];
-- Race procedures
GRANT EXECUTE ON [dbo].[sp_Race_GetByYear] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Race_GetByName] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Race_Insert] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Race_Delete] TO [db_f1_dataentry];
-- RaceResult procedures
GRANT EXECUTE ON [dbo].[sp_RaceResult_GetByRace] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_RaceResult_Insert] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_RaceResult_Delete] TO [db_f1_dataentry];
-- Qualifying procedures
GRANT EXECUTE ON [dbo].[sp_Qualifying_GetByRace] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Qualifying_Insert] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Qualifying_Delete] TO [db_f1_dataentry];
-- PitStop procedures
GRANT EXECUTE ON [dbo].[sp_PitStop_GetByRace] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_PitStop_Insert] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_PitStop_Delete] TO [db_f1_dataentry];
-- DriverContracts procedures
GRANT EXECUTE ON [dbo].[sp_DriverContracts_GetByDriver] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_DriverContracts_GetByTeam] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_DriverContracts_Insert] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_DriverContracts_Delete] TO [db_f1_dataentry];
-- Lookup procedures to enable functionality
GRANT EXECUTE ON [dbo].[sp_Nationality_GetAll] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Nationality_Insert] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Nationality_Delete] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Country_GetAll] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Country_Insert] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Country_Delete] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_City_GetAll] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_City_Insert] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_City_Delete] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Status_GetAll] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Status_Insert] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Status_Delete] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Seasons_GetAll] TO [db_f1_dataentry];
GRANT EXECUTE ON [dbo].[sp_Season_Insert] TO [db_f1_dataentry];
PRINT 'EXECUTE permissions granted to db_f1_dataentry role on CRUD procedures.'
GO

-- Assigning users to roles
ALTER ROLE [db_f1_admin] ADD MEMBER [f1_admin_user];
ALTER ROLE [db_f1_analyst] ADD MEMBER [f1_analyst_user];
ALTER ROLE [db_f1_dataentry] ADD MEMBER [f1_dataentry_user];
PRINT 'Users have been assigned to their corresponding roles.'
GO