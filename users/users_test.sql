-- ============================================================
-- TESTING DATABASE USERS AND PERMISSIONS
-- ============================================================

-- ============================================================
-- 1. TESTING ADMIN USER (f1_admin_user)
-- ============================================================
-- Connect with: f1_admin_user / f1_admin_user

-- Test 1: Check current user
USE Formula1
GO
SELECT SYSTEM_USER AS CurrentLogin, USER_NAME() AS CurrentUser;

-- Test 2: Admin should be able to SELECT from tables
SELECT TOP 5 * FROM dbo.Drivers;

-- Test 3: Admin should be able to INSERT
INSERT INTO dbo.RaceStatus (StatusName) VALUES ('Test Status');

-- Test 4: Admin should be able to UPDATE
UPDATE dbo.RaceStatus SET StatusName = 'Test Status Updated' WHERE StatusName = 'Test Status';

-- Test 5: Admin should be able to DELETE
DELETE FROM dbo.RaceStatus WHERE StatusName = 'Test Status Updated';

-- Test 6: Admin should be able to create objects
CREATE TABLE TestTable (ID INT, Name NVARCHAR(50));
DROP TABLE TestTable;

-- Test 7: Admin should be able to execute procedures
EXEC sp_Driver_GetAll;

PRINT 'ADMIN USER TESTS COMPLETED - All should succeed';
GO


-- ============================================================
-- 2. TESTING ANALYST USER (f1_analyst_user)
-- ============================================================
-- Connect with: f1_analyst_user / f1_analyst_user

-- Test 1: Check current user
SELECT SYSTEM_USER AS CurrentLogin, USER_NAME() AS CurrentUser;

-- Test 2: Analyst should be able to SELECT from tables
SELECT TOP 5 * FROM dbo.Drivers;

-- Test 3: Analyst should be able to SELECT from views
SELECT TOP 5 * FROM dbo.vw_DriverStandingsBySeason;

-- Test 4: Analyst should NOT be able to INSERT (should fail)
INSERT INTO dbo.RaceStatus (StatusName) VALUES ('Test Status');
-- Expected: Permission denied

-- Test 5: Analyst should NOT be able to UPDATE (should fail)
UPDATE dbo.Drivers SET surname = 'Test' WHERE DriverID = 1;
-- Expected: Permission denied

-- Test 6: Analyst should NOT be able to DELETE (should fail)
DELETE FROM dbo.RaceStatus WHERE StatusID = 1;
-- Expected: Permission denied

-- Test 7: Analyst should be able to execute analysis procedures
EXEC sp_Driver_GetAll;
EXEC sp_CompareDrivers @driver1Forename = 'Lewis', @driver1Surname = 'Hamilton', @driver2Forename = 'Max', @driver2Surname = 'Verstappen';
EXEC sp_AnalyzeTeamReliability @teamName = 'Mercedes', @year = 2024;

-- Test 8: Analyst should NOT be able to execute CRUD procedures (should fail)
EXEC sp_Driver_Insert 
    @FirstName = 'Test', 
    @LastName = 'Driver', 
    @DateOfBirth = '1990-01-01', 
    @NationalityID = 1;
-- Expected: Permission denied

-- Test 9: Analyst should NOT be able to create objects (should fail)
CREATE TABLE TestTable (ID INT);
-- Expected: Permission denied

PRINT 'ANALYST USER TESTS COMPLETED - Some should fail as expected';
GO


-- ============================================================
-- 3. TESTING DATA ENTRY USER (f1_dataentry_user)
-- ============================================================
-- Connect with: f1_dataentry_user / f1_dataentry_user

-- Test 1: Check current user
SELECT SYSTEM_USER AS CurrentLogin, USER_NAME() AS CurrentUser;

-- Test 2: Data Entry should NOT be able to SELECT directly from tables (should fail)
SELECT TOP 5 * FROM dbo.Drivers;
-- Expected: Permission denied

-- Test 3: Data Entry should be able to execute Get procedures
EXEC sp_Driver_GetAll;
EXEC sp_Team_GetAll;
EXEC sp_Circuit_GetAll;

-- Test 4: Data Entry should be able to execute Insert procedures
EXEC sp_Driver_Insert 
    @forename = 'John', 
    @surname = 'TestDriver', 
    @dob = '1995-03-15', 
    @nationalityName = 'American',
    @driverRef = 'testdriver',
    @number = 99,
    @code = 'TST';

-- Clean up
EXEC sp_Driver_Delete @forename = 'John', @surname = 'TestDriver';

-- Test 5: Data Entry should NOT be able to execute analysis procedures (should fail)
EXEC sp_CompareDrivers @driver1Forename = 'Lewis', @driver1Surname = 'Hamilton', @driver2Forename = 'Max', @driver2Surname = 'Verstappen';
-- Expected: Permission denied

-- Test 6 Data Entry should NOT be able to create objects (should fail)
CREATE TABLE TestTable (ID INT);
-- Expected: Permission denied

PRINT 'DATA ENTRY USER TESTS COMPLETED - Some should fail as expected';
GO


-- ============================================================
-- CHECKING USER PERMISSIONS (Run as admin)
-- ============================================================

-- View all permissions for f1_analyst_user
SELECT 
    USER_NAME(grantee_principal_id) AS User_Name,
    permission_name,
    state_desc,
    OBJECT_NAME(major_id) AS Object_Name
FROM sys.database_permissions
WHERE grantee_principal_id = USER_ID('f1_analyst_user')
ORDER BY permission_name;

-- View all permissions for f1_dataentry_user
SELECT 
    USER_NAME(grantee_principal_id) AS User_Name,
    permission_name,
    state_desc,
    OBJECT_NAME(major_id) AS Object_Name
FROM sys.database_permissions
WHERE grantee_principal_id = USER_ID('f1_dataentry_user')
ORDER BY permission_name;

-- View role memberships
SELECT 
    roles.name AS RoleName,
    members.name AS MemberName
FROM sys.database_role_members
JOIN sys.database_principals roles ON database_role_members.role_principal_id = roles.principal_id
JOIN sys.database_principals members ON database_role_members.member_principal_id = members.principal_id
WHERE members.name IN ('f1_admin_user', 'f1_analyst_user', 'f1_dataentry_user')
ORDER BY roles.name, members.name;


-- ============================================================
-- QUICK TEST SCRIPT FOR ALL USERS
-- ============================================================

-- Execute this to get a summary of what each user can do
-- (Run as admin)

PRINT '=== TESTING f1_admin_user ===';
EXECUTE AS USER = 'f1_admin_user';
    SELECT 'Admin can SELECT' AS Test, COUNT(*) AS Result FROM dbo.Drivers;
REVERT;

PRINT '=== TESTING f1_analyst_user ===';
EXECUTE AS USER = 'f1_analyst_user';
    SELECT 'Analyst can SELECT' AS Test, COUNT(*) AS Result FROM dbo.Drivers;
    BEGIN TRY
        INSERT INTO dbo.RaceStatus (statusName) VALUES ('Test');
        SELECT 'Analyst can INSERT' AS Test, 'FAIL - Should not allow' AS Result;
    END TRY
    BEGIN CATCH
        SELECT 'Analyst CANNOT INSERT' AS Test, 'PASS - Correctly denied' AS Result;
    END CATCH
REVERT;

PRINT '=== TESTING f1_dataentry_user ===';
EXECUTE AS USER = 'f1_dataentry_user';
    BEGIN TRY
        SELECT TOP 1 * FROM dbo.Drivers;
        SELECT 'DataEntry can SELECT directly' AS Test, 'FAIL - Should not allow' AS Result;
    END TRY
    BEGIN CATCH
        SELECT 'DataEntry CANNOT SELECT directly' AS Test, 'PASS - Correctly denied' AS Result;
    END CATCH
REVERT;

PRINT 'All user tests completed!';
GO