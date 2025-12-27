USE Formula1
GO

-- ============================================
-- FUNCȚII HELPER PENTRU CĂUTARE ID-URI
-- ============================================

-- Funcție pentru a găsi driverId după nume (forename + surname)
CREATE OR ALTER FUNCTION fn_GetDriverId
(
    @forename VARCHAR(100) = NULL,
    @surname VARCHAR(100) = NULL,
    @fullName VARCHAR(200) = NULL  -- Alternativ: "Lewis Hamilton"
)
RETURNS INT
AS
BEGIN
    DECLARE @driverId INT = NULL;
    
    -- Dacă s-a dat numele complet, îl splitează
    IF @fullName IS NOT NULL AND @forename IS NULL
    BEGIN
        SET @forename = LTRIM(RTRIM(LEFT(@fullName, CHARINDEX(' ', @fullName + ' ') - 1)));
        SET @surname = LTRIM(RTRIM(SUBSTRING(@fullName, CHARINDEX(' ', @fullName + ' ') + 1, LEN(@fullName))));
    END
    
    -- Caută exact
    SELECT @driverId = driverId 
    FROM Drivers 
    WHERE (@forename IS NULL OR forename = @forename)
      AND (@surname IS NULL OR surname = @surname);
    
    -- Dacă nu găsește exact, caută parțial (LIKE)
    IF @driverId IS NULL
    BEGIN
        SELECT TOP 1 @driverId = driverId 
        FROM Drivers 
        WHERE (@forename IS NULL OR forename LIKE '%' + @forename + '%')
          AND (@surname IS NULL OR surname LIKE '%' + @surname + '%');
    END
    
    RETURN @driverId;
END
GO

-- Funcție pentru a găsi constructorId după numele echipei
CREATE OR ALTER FUNCTION fn_GetTeamId
(
    @teamName VARCHAR(200)
)
RETURNS INT
AS
BEGIN
    DECLARE @constructorId INT = NULL;
    
    -- Caută exact
    SELECT @constructorId = constructorId FROM Teams WHERE name = @teamName;
    
    -- Dacă nu găsește, caută parțial
    IF @constructorId IS NULL
        SELECT TOP 1 @constructorId = constructorId 
        FROM Teams 
        WHERE name LIKE '%' + @teamName + '%';
    
    RETURN @constructorId;
END
GO

-- Funcție pentru a găsi circuitId după nume
CREATE OR ALTER FUNCTION fn_GetCircuitId
(
    @circuitName VARCHAR(200)
)
RETURNS INT
AS
BEGIN
    DECLARE @circuitId INT = NULL;
    
    SELECT @circuitId = circuitId FROM Circuits WHERE name = @circuitName;
    
    IF @circuitId IS NULL
        SELECT TOP 1 @circuitId = circuitId 
        FROM Circuits 
        WHERE name LIKE '%' + @circuitName + '%';
    
    RETURN @circuitId;
END
GO

-- Funcție pentru a găsi nationalityId după nume
CREATE OR ALTER FUNCTION fn_GetNationalityId
(
    @nationalityName VARCHAR(100)
)
RETURNS INT
AS
BEGIN
    DECLARE @nationalityId INT = NULL;
    
    SELECT @nationalityId = nationalityId 
    FROM Nationalities 
    WHERE nationalityName = @nationalityName;
    
    IF @nationalityId IS NULL
        SELECT TOP 1 @nationalityId = nationalityId 
        FROM Nationalities 
        WHERE nationalityName LIKE '%' + @nationalityName + '%';
    
    RETURN @nationalityId;
END
GO

-- Funcție pentru a găsi countryId după nume
CREATE OR ALTER FUNCTION fn_GetCountryId
(
    @countryName VARCHAR(100)
)
RETURNS INT
AS
BEGIN
    DECLARE @countryId INT = NULL;
    
    SELECT @countryId = countryId FROM Countries WHERE countryName = @countryName;
    
    IF @countryId IS NULL
        SELECT TOP 1 @countryId = countryId 
        FROM Countries 
        WHERE countryName LIKE '%' + @countryName + '%';
    
    RETURN @countryId;
END
GO

-- Funcție pentru a găsi cityId după nume
CREATE OR ALTER FUNCTION fn_GetCityId
(
    @cityName VARCHAR(100),
    @countryName VARCHAR(100) = NULL
)
RETURNS INT
AS
BEGIN
    DECLARE @cityId INT = NULL;
    DECLARE @countryId INT = NULL;
    
    IF @countryName IS NOT NULL
        SET @countryId = dbo.fn_GetCountryId(@countryName);
    
    SELECT @cityId = cityId 
    FROM Cities 
    WHERE cityName = @cityName
      AND (@countryId IS NULL OR countryId = @countryId);
    
    IF @cityId IS NULL
        SELECT TOP 1 @cityId = cityId 
        FROM Cities 
        WHERE cityName LIKE '%' + @cityName + '%'
          AND (@countryId IS NULL OR countryId = @countryId);
    
    RETURN @cityId;
END
GO

-- Funcție pentru a găsi raceId după nume și an
CREATE OR ALTER FUNCTION fn_GetRaceId
(
    @raceName VARCHAR(200) = NULL,
    @year INT = NULL,
    @round INT = NULL
)
RETURNS INT
AS
BEGIN
    DECLARE @raceId INT = NULL;
    
    SELECT @raceId = raceId 
    FROM Races 
    WHERE (@raceName IS NULL OR name = @raceName)
      AND (@year IS NULL OR year = @year)
      AND (@round IS NULL OR round = @round);
    
    IF @raceId IS NULL
        SELECT TOP 1 @raceId = raceId 
        FROM Races 
        WHERE (@raceName IS NULL OR name LIKE '%' + @raceName + '%')
          AND (@year IS NULL OR year = @year)
        ORDER BY year DESC;
    
    RETURN @raceId;
END
GO

-- Funcție pentru a găsi statusId după nume
CREATE OR ALTER FUNCTION fn_GetStatusId
(
    @statusName VARCHAR(50)
)
RETURNS INT
AS
BEGIN
    DECLARE @statusId INT = NULL;
    
    SELECT @statusId = statusId FROM RaceStatus WHERE statusName = @statusName;
    
    IF @statusId IS NULL
        SELECT TOP 1 @statusId = statusId 
        FROM RaceStatus 
        WHERE statusName LIKE '%' + @statusName + '%';
    
    RETURN @statusId;
END
GO

-- ============================================
-- PARTEA 1: PROCEDURI STOCATE CRUD - BY NAME
-- ============================================

-- =====================
-- CRUD pentru Drivers (BY NAME)
-- =====================

-- CREATE - acceptă nationality ca nume
CREATE OR ALTER PROCEDURE sp_Driver_Insert
    @driverRef VARCHAR(100),
    @forename VARCHAR(100),
    @surname VARCHAR(100),
    @number VARCHAR(3) = NULL,
    @code VARCHAR(3) = NULL,
    @dob DATE = NULL,
    @nationalityName VARCHAR(100) = NULL  -- Acum acceptă nume, nu ID! 
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @nationalityId INT = NULL;
    DECLARE @newDriverId INT;
    
    BEGIN TRY
        -- Găsește nationalityId după nume
        IF @nationalityName IS NOT NULL
        BEGIN
            SET @nationalityId = dbo.fn_GetNationalityId(@nationalityName);
            
            IF @nationalityId IS NULL
            BEGIN
                SELECT 'ERROR' AS Status, 
                       'Nationality not found:  ' + @nationalityName AS ErrorMessage,
                       'Available nationalities: Use sp_Nationality_GetAll to see list' AS Hint;
                RETURN;
            END
        END
        
        -- Generează noul driverId
        SELECT @newDriverId = ISNULL(MAX(driverId), 0) + 1 FROM Drivers;
        
        INSERT INTO Drivers (driverId, driverRef, number, code, forename, surname, dob, nationalityId)
        VALUES (@newDriverId, @driverRef, @number, @code, @forename, @surname, @dob, @nationalityId);
        
        SELECT 'SUCCESS' AS Status, 
               @newDriverId AS InsertedId,
               @forename + ' ' + @surname AS DriverName,
               @nationalityName AS Nationality;
    END TRY
    BEGIN CATCH
        SELECT 'ERROR' AS Status, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- READ - după nume
CREATE OR ALTER PROCEDURE sp_Driver_GetByName
    @forename VARCHAR(100) = NULL,
    @surname VARCHAR(100) = NULL,
    @fullName VARCHAR(200) = NULL  -- Poți da "Lewis Hamilton"
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Dacă s-a dat numele complet, îl splitează
    IF @fullName IS NOT NULL AND @forename IS NULL
    BEGIN
        SET @forename = LTRIM(RTRIM(LEFT(@fullName, CHARINDEX(' ', @fullName + ' ') - 1)));
        SET @surname = LTRIM(RTRIM(SUBSTRING(@fullName, CHARINDEX(' ', @fullName + ' ') + 1, LEN(@fullName))));
    END
    
    SELECT d.*, n.nationalityName 
    FROM Drivers d
    LEFT JOIN Nationalities n ON d.nationalityId = n.nationalityId
    WHERE (@forename IS NULL OR d.forename LIKE '%' + @forename + '%')
      AND (@surname IS NULL OR d.surname LIKE '%' + @surname + '%')
    ORDER BY d.surname, d.forename;
END
GO

-- READ toate
CREATE OR ALTER PROCEDURE sp_Driver_GetAll
AS
BEGIN
    SET NOCOUNT ON;
    SELECT d.*, n.nationalityName 
    FROM Drivers d
    LEFT JOIN Nationalities n ON d. nationalityId = n.nationalityId
    ORDER BY d. surname, d.forename;
END
GO

-- UPDATE - folosește nume pentru identificare și pentru nationality
CREATE OR ALTER PROCEDURE sp_Driver_Update
    @forename VARCHAR(100),           -- Pentru identificare
    @surname VARCHAR(100),            -- Pentru identificare
    @newDriverRef VARCHAR(100) = NULL,
    @newNumber VARCHAR(3) = NULL,
    @newCode VARCHAR(3) = NULL,
    @newForename VARCHAR(100) = NULL,
    @newSurname VARCHAR(100) = NULL,
    @newDob DATE = NULL,
    @newNationalityName VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @driverId INT;
    DECLARE @nationalityId INT = NULL;
    
    BEGIN TRY
        -- Găsește pilotul după nume
        SET @driverId = dbo.fn_GetDriverId(@forename, @surname, NULL);
        
        IF @driverId IS NULL
        BEGIN
            SELECT 'ERROR' AS Status, 
                   'Driver not found: ' + @forename + ' ' + @surname AS ErrorMessage;
            RETURN;
        END
        
        -- Găsește noua naționalitate dacă e specificată
        IF @newNationalityName IS NOT NULL
        BEGIN
            SET @nationalityId = dbo.fn_GetNationalityId(@newNationalityName);
            IF @nationalityId IS NULL
            BEGIN
                SELECT 'ERROR' AS Status, 
                       'Nationality not found: ' + @newNationalityName AS ErrorMessage;
                RETURN;
            END
        END
        
        UPDATE Drivers
        SET driverRef = ISNULL(@newDriverRef, driverRef),
            number = ISNULL(@newNumber, number),
            code = ISNULL(@newCode, code),
            forename = ISNULL(@newForename, forename),
            surname = ISNULL(@newSurname, surname),
            dob = ISNULL(@newDob, dob),
            nationalityId = ISNULL(@nationalityId, nationalityId)
        WHERE driverId = @driverId;
        
        SELECT 'SUCCESS' AS Status, 
               @driverId AS UpdatedDriverId,
               @@ROWCOUNT AS RowsAffected;
    END TRY
    BEGIN CATCH
        SELECT 'ERROR' AS Status, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- DELETE - folosește nume
CREATE OR ALTER PROCEDURE sp_Driver_Delete
    @forename VARCHAR(100),
    @surname VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @driverId INT;
    
    BEGIN TRY
        SET @driverId = dbo.fn_GetDriverId(@forename, @surname, NULL);
        
        IF @driverId IS NULL
        BEGIN
            SELECT 'ERROR' AS Status, 
                   'Driver not found:  ' + @forename + ' ' + @surname AS ErrorMessage;
            RETURN;
        END
        
        -- Verifică dacă există rezultate asociate
        IF EXISTS (SELECT 1 FROM RaceResults WHERE driverId = @driverId)
        BEGIN
            SELECT 'ERROR' AS Status, 
                   'Cannot delete driver with existing race results' AS ErrorMessage,
                   @forename + ' ' + @surname AS Driver;
            RETURN;
        END
        
        DELETE FROM Drivers WHERE driverId = @driverId;
        SELECT 'SUCCESS' AS Status, 
               @forename + ' ' + @surname AS DeletedDriver,
               @@ROWCOUNT AS RowsDeleted;
    END TRY
    BEGIN CATCH
        SELECT 'ERROR' AS Status, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- =====================
-- CRUD pentru Teams (BY NAME)
-- =====================

CREATE OR ALTER PROCEDURE sp_Team_Insert
    @constructorRef VARCHAR(100),
    @name VARCHAR(200),
    @nationalityName VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @nationalityId INT = NULL;
    DECLARE @newConstructorId INT;
    
    BEGIN TRY
        IF @nationalityName IS NOT NULL
        BEGIN
            SET @nationalityId = dbo.fn_GetNationalityId(@nationalityName);
            IF @nationalityId IS NULL
            BEGIN
                SELECT 'ERROR' AS Status, 
                       'Nationality not found: ' + @nationalityName AS ErrorMessage;
                RETURN;
            END
        END
        
        SELECT @newConstructorId = ISNULL(MAX(constructorId), 0) + 1 FROM Teams;
        
        INSERT INTO Teams (constructorId, constructorRef, name, nationalityId)
        VALUES (@newConstructorId, @constructorRef, @name, @nationalityId);
        
        SELECT 'SUCCESS' AS Status, 
               @newConstructorId AS InsertedId,
               @name AS TeamName;
    END TRY
    BEGIN CATCH
        SELECT 'ERROR' AS Status, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE sp_Team_GetByName
    @teamName VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT t.*, n. nationalityName 
    FROM Teams t
    LEFT JOIN Nationalities n ON t. nationalityId = n.nationalityId
    WHERE t.name LIKE '%' + @teamName + '%'
    ORDER BY t.name;
END
GO

CREATE OR ALTER PROCEDURE sp_Team_GetAll
AS
BEGIN
    SET NOCOUNT ON;
    SELECT t.*, n.nationalityName 
    FROM Teams t
    LEFT JOIN Nationalities n ON t.nationalityId = n.nationalityId
    ORDER BY t.name;
END
GO

CREATE OR ALTER PROCEDURE sp_Team_Update
    @teamName VARCHAR(200),              -- Pentru identificare
    @newConstructorRef VARCHAR(100) = NULL,
    @newName VARCHAR(200) = NULL,
    @newNationalityName VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @constructorId INT;
    DECLARE @nationalityId INT = NULL;
    
    BEGIN TRY
        SET @constructorId = dbo. fn_GetTeamId(@teamName);
        
        IF @constructorId IS NULL
        BEGIN
            SELECT 'ERROR' AS Status, 'Team not found: ' + @teamName AS ErrorMessage;
            RETURN;
        END
        
        IF @newNationalityName IS NOT NULL
        BEGIN
            SET @nationalityId = dbo.fn_GetNationalityId(@newNationalityName);
            IF @nationalityId IS NULL
            BEGIN
                SELECT 'ERROR' AS Status, 
                       'Nationality not found: ' + @newNationalityName AS ErrorMessage;
                RETURN;
            END
        END
        
        UPDATE Teams
        SET constructorRef = ISNULL(@newConstructorRef, constructorRef),
            name = ISNULL(@newName, name),
            nationalityId = ISNULL(@nationalityId, nationalityId)
        WHERE constructorId = @constructorId;
        
        SELECT 'SUCCESS' AS Status, @@ROWCOUNT AS RowsAffected;
    END TRY
    BEGIN CATCH
        SELECT 'ERROR' AS Status, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE sp_Team_Delete
    @teamName VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @constructorId INT;
    
    BEGIN TRY
        SET @constructorId = dbo.fn_GetTeamId(@teamName);
        
        IF @constructorId IS NULL
        BEGIN
            SELECT 'ERROR' AS Status, 'Team not found: ' + @teamName AS ErrorMessage;
            RETURN;
        END
        
        IF EXISTS (SELECT 1 FROM RaceResults WHERE constructorId = @constructorId)
        BEGIN
            SELECT 'ERROR' AS Status, 
                   'Cannot delete team with existing race results' AS ErrorMessage;
            RETURN;
        END
        
        DELETE FROM Teams WHERE constructorId = @constructorId;
        SELECT 'SUCCESS' AS Status, @teamName AS DeletedTeam;
    END TRY
    BEGIN CATCH
        SELECT 'ERROR' AS Status, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- =====================
-- CRUD pentru Races (BY NAME)
-- =====================

CREATE OR ALTER PROCEDURE sp_Race_Insert
    @year INT,
    @round INT,
    @circuitName VARCHAR(200),  -- Acceptă nume circuit! 
    @name VARCHAR(200),
    @date DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @circuitId INT;
    DECLARE @newRaceId INT;
    
    BEGIN TRY
        -- Găsește circuitul după nume
        SET @circuitId = dbo.fn_GetCircuitId(@circuitName);
        
        IF @circuitId IS NULL
        BEGIN
            SELECT 'ERROR' AS Status, 
                   'Circuit not found: ' + @circuitName AS ErrorMessage,
                   'Use sp_Circuit_GetAll to see available circuits' AS Hint;
            RETURN;
        END
        
        -- Verifică dacă sezonul există
        IF NOT EXISTS (SELECT 1 FROM Seasons WHERE year = @year)
        BEGIN
            INSERT INTO Seasons (year) VALUES (@year);
        END
        
        SELECT @newRaceId = ISNULL(MAX(raceId), 0) + 1 FROM Races;
        
        INSERT INTO Races (raceId, year, round, circuitId, name, date)
        VALUES (@newRaceId, @year, @round, @circuitId, @name, @date);
        
        SELECT 'SUCCESS' AS Status, 
               @newRaceId AS InsertedId,
               @name AS RaceName,
               @circuitName AS Circuit;
    END TRY
    BEGIN CATCH
        SELECT 'ERROR' AS Status, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE sp_Race_GetByName
    @raceName VARCHAR(200) = NULL,
    @year INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT r.*, c.name AS circuitName, co.countryName
    FROM Races r
    INNER JOIN Circuits c ON r.circuitId = c.circuitId
    LEFT JOIN Countries co ON c.countryId = co.countryId
    WHERE (@raceName IS NULL OR r.name LIKE '%' + @raceName + '%')
      AND (@year IS NULL OR r.year = @year)
    ORDER BY r.year DESC, r.round;
END
GO

CREATE OR ALTER PROCEDURE sp_Race_GetByYear
    @year INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT r.*, c.name AS circuitName, co.countryName
    FROM Races r
    INNER JOIN Circuits c ON r.circuitId = c.circuitId
    LEFT JOIN Countries co ON c. countryId = co.countryId
    WHERE r.year = @year
    ORDER BY r.round;
END
GO

-- =====================
-- CRUD pentru RaceResults (BY NAME)
-- =====================

CREATE OR ALTER PROCEDURE sp_RaceResult_Insert
    @raceName VARCHAR(200),           -- Nume cursă
    @raceYear INT,                    -- An (pentru identificare unică)
    @driverForename VARCHAR(100),     -- Prenume pilot
    @driverSurname VARCHAR(100),      -- Nume pilot  
    @teamName VARCHAR(200),           -- Nume echipă
    @grid INT = NULL,
    @position VARCHAR(10) = NULL,
    @positionOrder INT = NULL,
    @points DECIMAL(5,2) = NULL,
    @laps INT = NULL,
    @time VARCHAR(50) = NULL,
    @milliseconds INT = NULL,
    @fastestLap INT = NULL,
    @fastestLapTime VARCHAR(20) = NULL,
    @fastestLapSpeed VARCHAR(20) = NULL,
    @statusName VARCHAR(50) = NULL    -- Status ca text
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @raceId INT, @driverId INT, @constructorId INT, @statusId INT;
    DECLARE @newResultId INT;
    
    BEGIN TRY
        -- Găsește toate ID-urile
        SET @raceId = dbo.fn_GetRaceId(@raceName, @raceYear, NULL);
        SET @driverId = dbo.fn_GetDriverId(@driverForename, @driverSurname, NULL);
        SET @constructorId = dbo.fn_GetTeamId(@teamName);
        SET @statusId = dbo.fn_GetStatusId(@statusName);
        
        -- Validări
        IF @raceId IS NULL
        BEGIN
            SELECT 'ERROR' AS Status, 
                   'Race not found: ' + @raceName + ' (' + CAST(@raceYear AS VARCHAR) + ')' AS ErrorMessage;
            RETURN;
        END
        
        IF @driverId IS NULL
        BEGIN
            SELECT 'ERROR' AS Status, 
                   'Driver not found:  ' + @driverForename + ' ' + @driverSurname AS ErrorMessage;
            RETURN;
        END
        
        IF @constructorId IS NULL
        BEGIN
            SELECT 'ERROR' AS Status, 
                   'Team not found: ' + @teamName AS ErrorMessage;
            RETURN;
        END
        
        SELECT @newResultId = ISNULL(MAX(resultId), 0) + 1 FROM RaceResults;
        
        INSERT INTO RaceResults (resultId, raceId, driverId, constructorId, grid, position, 
                                positionOrder, points, laps, time, milliseconds, 
                                fastestLap, fastestLapTime, fastestLapSpeed, statusId)
        VALUES (@newResultId, @raceId, @driverId, @constructorId, @grid, @position,
                @positionOrder, @points, @laps, @time, @milliseconds,
                @fastestLap, @fastestLapTime, @fastestLapSpeed, @statusId);
        
        SELECT 'SUCCESS' AS Status, 
               @newResultId AS InsertedId,
               @driverForename + ' ' + @driverSurname AS Driver,
               @teamName AS Team,
               @raceName AS Race;
    END TRY
    BEGIN CATCH
        SELECT 'ERROR' AS Status, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- =====================
-- CRUD pentru PitStops (BY NAME)
-- =====================

CREATE OR ALTER PROCEDURE sp_PitStop_Insert
    @raceName VARCHAR(200),
    @raceYear INT,
    @driverForename VARCHAR(100),
    @driverSurname VARCHAR(100),
    @stop INT,
    @lap INT,
    @duration VARCHAR(20) = NULL,
    @milliseconds INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @raceId INT, @driverId INT;
    
    BEGIN TRY
        SET @raceId = dbo.fn_GetRaceId(@raceName, @raceYear, NULL);
        SET @driverId = dbo.fn_GetDriverId(@driverForename, @driverSurname, NULL);
        
        IF @raceId IS NULL
        BEGIN
            SELECT 'ERROR' AS Status, 
                   'Race not found: ' + @raceName + ' (' + CAST(@raceYear AS VARCHAR) + ')' AS ErrorMessage;
            RETURN;
        END
        
        IF @driverId IS NULL
        BEGIN
            SELECT 'ERROR' AS Status, 
                   'Driver not found: ' + @driverForename + ' ' + @driverSurname AS ErrorMessage;
            RETURN;
        END
        
        INSERT INTO PitStops (raceId, driverId, stop, lap, duration, milliseconds)
        VALUES (@raceId, @driverId, @stop, @lap, @duration, @milliseconds);
        
        SELECT 'SUCCESS' AS Status,
               @driverForename + ' ' + @driverSurname AS Driver,
               @raceName AS Race,
               @stop AS StopNumber;
    END TRY
    BEGIN CATCH
        SELECT 'ERROR' AS Status, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- =====================
-- CRUD pentru Circuits (BY NAME)
-- =====================

CREATE OR ALTER PROCEDURE sp_Circuit_Insert
    @circuitRef VARCHAR(100),
    @name VARCHAR(200),
    @cityName VARCHAR(100) = NULL,
    @countryName VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @cityId INT = NULL, @countryId INT = NULL;
    DECLARE @newCircuitId INT;
    
    BEGIN TRY
        IF @countryName IS NOT NULL
        BEGIN
            SET @countryId = dbo.fn_GetCountryId(@countryName);
            IF @countryId IS NULL
            BEGIN
                SELECT 'ERROR' AS Status, 
                       'Country not found: ' + @countryName AS ErrorMessage;
                RETURN;
            END
        END
        
        IF @cityName IS NOT NULL
        BEGIN
            SET @cityId = dbo.fn_GetCityId(@cityName, @countryName);
            IF @cityId IS NULL
            BEGIN
                SELECT 'ERROR' AS Status, 
                       'City not found: ' + @cityName AS ErrorMessage;
                RETURN;
            END
        END
        
        SELECT @newCircuitId = ISNULL(MAX(circuitId), 0) + 1 FROM Circuits;
        
        INSERT INTO Circuits (circuitId, circuitRef, name, cityId, countryId)
        VALUES (@newCircuitId, @circuitRef, @name, @cityId, @countryId);
        
        SELECT 'SUCCESS' AS Status, 
               @newCircuitId AS InsertedId,
               @name AS CircuitName;
    END TRY
    BEGIN CATCH
        SELECT 'ERROR' AS Status, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE sp_Circuit_GetByName
    @circuitName VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.*, ci.cityName, co.countryName
    FROM Circuits c
    LEFT JOIN Cities ci ON c.cityId = ci.cityId
    LEFT JOIN Countries co ON c.countryId = co.countryId
    WHERE c. name LIKE '%' + @circuitName + '%'
    ORDER BY c.name;
END
GO

CREATE OR ALTER PROCEDURE sp_Circuit_GetAll
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.*, ci. cityName, co. countryName
    FROM Circuits c
    LEFT JOIN Cities ci ON c.cityId = ci.cityId
    LEFT JOIN Countries co ON c.countryId = co. countryId
    ORDER BY c.name;
END
GO

-- =====================
-- Proceduri helper pentru nomenclatoare
-- =====================

CREATE OR ALTER PROCEDURE sp_Nationality_GetAll
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM Nationalities ORDER BY nationalityName;
END
GO

CREATE OR ALTER PROCEDURE sp_Country_GetAll
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.*, con.continentName 
    FROM Countries c
    LEFT JOIN Continents con ON c.continentId = con.continentId
    ORDER BY c.countryName;
END
GO

CREATE OR ALTER PROCEDURE sp_Status_GetAll
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM RaceStatus ORDER BY statusName;
END
GO

-- ============================================
-- PARTEA 2: FUNCȚII DE ANALIZĂ - BY NAME
-- ============================================

-- Strategia Optimă de PitStop - BY CIRCUIT NAME
CREATE OR ALTER PROCEDURE sp_AnalyzeOptimalPitStrategy
    @circuitName VARCHAR(200),  -- Acceptă nume! 
    @topN INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @circuitId INT;
    SET @circuitId = dbo.fn_GetCircuitId(@circuitName);
    
    IF @circuitId IS NULL
    BEGIN
        SELECT 'ERROR' AS Status, 
               'Circuit not found: ' + @circuitName AS ErrorMessage;
        RETURN;
    END
    
    -- Afișează circuitul găsit
    SELECT 'Analyzing circuit: ' + c.name AS Info, 
           ci.cityName AS City, 
           co.countryName AS Country
    FROM Circuits c
    LEFT JOIN Cities ci ON c.cityId = ci.cityId
    LEFT JOIN Countries co ON c.countryId = co.countryId
    WHERE c.circuitId = @circuitId;
    
    -- Tabelă temporară pentru rezultate
    CREATE TABLE #StrategyAnalysis (
        RaceYear INT,
        RaceName VARCHAR(200),
        DriverName VARCHAR(200),
        FinishPosition INT,
        TotalPitStops INT,
        TotalPitTime INT,
        AvgPitTime INT
    );
    
    INSERT INTO #StrategyAnalysis
    SELECT 
        r.year,
        r.name,
        d.forename + ' ' + d.surname,
        rr.positionOrder,
        COUNT(ps.stop),
        SUM(ps.milliseconds),
        AVG(ps.milliseconds)
    FROM Races r
    INNER JOIN RaceResults rr ON r. raceId = rr.raceId
    INNER JOIN Drivers d ON rr.driverId = d.driverId
    LEFT JOIN PitStops ps ON r.raceId = ps.raceId AND rr. driverId = ps. driverId
    WHERE r.circuitId = @circuitId
      AND rr.positionOrder <= @topN
      AND rr.positionOrder IS NOT NULL
    GROUP BY r.year, r.name, d.forename, d.surname, rr.positionOrder;
    
    -- Rezultat 1: Statistici per număr de opriri
    SELECT 
        'STRATEGIA OPTIMĂ PE CIRCUIT' AS AnalysisType,
        TotalPitStops AS NumarOpriri,
        COUNT(*) AS CazuriAnalizate,
        AVG(FinishPosition) AS PozitieFinishMedie,
        MIN(FinishPosition) AS CeaMaiBunaPozitie,
        COUNT(CASE WHEN FinishPosition = 1 THEN 1 END) AS Victorii,
        COUNT(CASE WHEN FinishPosition <= 3 THEN 1 END) AS Podiumuri
    FROM #StrategyAnalysis
    WHERE TotalPitStops IS NOT NULL
    GROUP BY TotalPitStops
    ORDER BY AVG(FinishPosition);
    
    -- Rezultat 2: Recomandare
    SELECT TOP 1
        'RECOMANDARE' AS Tip,
        TotalPitStops AS NumarOptimOpriri,
        'Bazat pe ' + CAST(COUNT(*) AS VARCHAR) + ' curse analizate' AS Detalii,
        CAST(AVG(FinishPosition) AS DECIMAL(5,2)) AS PozitieFinishMedie
    FROM #StrategyAnalysis
    WHERE TotalPitStops IS NOT NULL
    GROUP BY TotalPitStops
    ORDER BY AVG(FinishPosition), COUNT(*) DESC;
    
    DROP TABLE #StrategyAnalysis;
END
GO

-- Evoluția Performanței Pilotului - BY NAME
CREATE OR ALTER PROCEDURE sp_AnalyzeDriverSeasonPerformance
    @driverForename VARCHAR(100) = NULL,
    @driverSurname VARCHAR(100) = NULL,
    @driverFullName VARCHAR(200) = NULL,  -- Alternativ: "Lewis Hamilton"
    @year INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @driverId INT;
    
    -- Găsește pilotul
    SET @driverId = dbo.fn_GetDriverId(@driverForename, @driverSurname, @driverFullName);
    
    IF @driverId IS NULL
    BEGIN
        SELECT 'ERROR' AS Status, 
               'Driver not found: ' + ISNULL(@driverFullName, @driverForename + ' ' + @driverSurname) AS ErrorMessage;
        RETURN;
    END
    
    -- Afișează pilotul găsit
    SELECT 'Analyzing driver: ' + forename + ' ' + surname AS Info,
           code AS DriverCode
    FROM Drivers WHERE driverId = @driverId;
    
    -- Performanța cursă cu cursă
    SELECT 
        r.round AS Etapa,
        r. name AS Cursa,
        r.date AS Data,
        c.name AS Circuit,
        t.name AS Echipa,
        q.position AS PozitieCalificare,
        rr.grid AS PozitieStart,
        rr.positionOrder AS PozitieFinish,
        rr.points AS Puncte,
        rs.statusName AS Status,
        rr.grid - rr.positionOrder AS PozitiiCastigate,
        SUM(rr.points) OVER (ORDER BY r.round) AS PuncteCumulate,
        CAST(AVG(CAST(rr. positionOrder AS FLOAT)) OVER (ORDER BY r.round ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS DECIMAL(5,2)) AS MediaPozitiiPanaAcum
    FROM Races r
    INNER JOIN RaceResults rr ON r.raceId = rr. raceId
    INNER JOIN Circuits c ON r.circuitId = c. circuitId
    INNER JOIN Teams t ON rr.constructorId = t. constructorId
    LEFT JOIN QualifyingResults q ON r.raceId = q. raceId AND rr. driverId = q. driverId
    LEFT JOIN RaceStatus rs ON rr.statusId = rs.statusId
    WHERE rr.driverId = @driverId AND r.year = @year
    ORDER BY r.round;
    
    -- Sumar sezon
    SELECT 
        'SUMAR SEZON ' + CAST(@year AS VARCHAR) AS Raport,
        d.forename + ' ' + d.surname AS Pilot,
        COUNT(*) AS CurseParticipate,
        SUM(rr.points) AS TotalPuncte,
        SUM(CASE WHEN rr.positionOrder = 1 THEN 1 ELSE 0 END) AS Victorii,
        SUM(CASE WHEN rr.positionOrder <= 3 THEN 1 ELSE 0 END) AS Podiumuri,
        SUM(CASE WHEN rr.positionOrder <= 10 THEN 1 ELSE 0 END) AS InPuncte,
        CAST(AVG(CAST(rr.positionOrder AS FLOAT)) AS DECIMAL(5,2)) AS PozitieFinishMedie,
        CAST(AVG(CAST(rr.grid AS FLOAT)) AS DECIMAL(5,2)) AS PozitieStartMedie
    FROM RaceResults rr
    INNER JOIN Races r ON rr. raceId = r.raceId
    INNER JOIN Drivers d ON rr. driverId = d.driverId
    WHERE rr. driverId = @driverId AND r.year = @year
    GROUP BY d.forename, d.surname;
END
GO

-- Comparație Directă între Doi Piloți - BY NAME
CREATE OR ALTER PROCEDURE sp_CompareDrivers
    @driver1FullName VARCHAR(200) = NULL,
    @driver1Forename VARCHAR(100) = NULL,
    @driver1Surname VARCHAR(100) = NULL,
    @driver2FullName VARCHAR(200) = NULL,
    @driver2Forename VARCHAR(100) = NULL,
    @driver2Surname VARCHAR(100) = NULL,
    @yearFrom INT = NULL,
    @yearTo INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @driver1Id INT, @driver2Id INT;
    
    SET @driver1Id = dbo.fn_GetDriverId(@driver1Forename, @driver1Surname, @driver1FullName);
    SET @driver2Id = dbo.fn_GetDriverId(@driver2Forename, @driver2Surname, @driver2FullName);
    
    IF @driver1Id IS NULL
    BEGIN
        SELECT 'ERROR' AS Status, 
               'Driver 1 not found:  ' + ISNULL(@driver1FullName, @driver1Forename + ' ' + @driver1Surname) AS ErrorMessage;
        RETURN;
    END
    
    IF @driver2Id IS NULL
    BEGIN
        SELECT 'ERROR' AS Status, 
               'Driver 2 not found: ' + ISNULL(@driver2FullName, @driver2Forename + ' ' + @driver2Surname) AS ErrorMessage;
        RETURN;
    END
    
    SET @yearFrom = ISNULL(@yearFrom, 1950);
    SET @yearTo = ISNULL(@yearTo, 2025);
    
    -- Găsește cursele în care au participat amândoi
    ;WITH CommonRaces AS (
        SELECT DISTINCT rr1.raceId
        FROM RaceResults rr1
        INNER JOIN RaceResults rr2 ON rr1.raceId = rr2.raceId
        INNER JOIN Races r ON rr1.raceId = r.raceId
        WHERE rr1.driverId = @driver1Id 
          AND rr2.driverId = @driver2Id
          AND r.year BETWEEN @yearFrom AND @yearTo
    )
    SELECT 
        d1.forename + ' ' + d1.surname AS Pilot1,
        d2.forename + ' ' + d2.surname AS Pilot2,
        COUNT(*) AS CurseComune,
        SUM(CASE WHEN rr1.positionOrder < rr2.positionOrder THEN 1 ELSE 0 END) AS VictoriiPilot1,
        SUM(CASE WHEN rr2.positionOrder < rr1.positionOrder THEN 1 ELSE 0 END) AS VictoriiPilot2,
        SUM(CASE WHEN rr1.positionOrder = rr2.positionOrder THEN 1 ELSE 0 END) AS Egaluri,
        SUM(rr1.points) AS PunctePilot1,
        SUM(rr2.points) AS PunctePilot2,
        CAST(AVG(CAST(rr1.positionOrder AS FLOAT)) AS DECIMAL(5,2)) AS PozMediePilot1,
        CAST(AVG(CAST(rr2.positionOrder AS FLOAT)) AS DECIMAL(5,2)) AS PozMediePilot2
    FROM CommonRaces cr
    INNER JOIN RaceResults rr1 ON cr.raceId = rr1.raceId AND rr1.driverId = @driver1Id
    INNER JOIN RaceResults rr2 ON cr.raceId = rr2.raceId AND rr2.driverId = @driver2Id
    INNER JOIN Drivers d1 ON rr1.driverId = d1.driverId
    INNER JOIN Drivers d2 ON rr2.driverId = d2.driverId
    GROUP BY d1.forename, d1.surname, d2.forename, d2.surname;
END
GO

-- Analiza Fiabilității Echipei - BY NAME
CREATE OR ALTER PROCEDURE sp_AnalyzeTeamReliability
    @teamName VARCHAR(200),
    @year INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @constructorId INT;
    SET @constructorId = dbo.fn_GetTeamId(@teamName);
    
    IF @constructorId IS NULL
    BEGIN
        SELECT 'ERROR' AS Status, 
               'Team not found: ' + @teamName AS ErrorMessage;
        RETURN;
    END
    
    SELECT 
        r.year AS Sezon,
        t.name AS Echipa,
        COUNT(*) AS TotalStarturi,
        SUM(CASE WHEN rs.statusName = 'Finished' THEN 1 ELSE 0 END) AS Finalizate,
        SUM(CASE WHEN rs.statusName != 'Finished' THEN 1 ELSE 0 END) AS Abandonuri,
        CAST(100.0 * SUM(CASE WHEN rs.statusName = 'Finished' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS ProcentFiabilitate,
        SUM(rr.points) AS PuncteObtinute
    FROM RaceResults rr
    INNER JOIN Races r ON rr.raceId = r.raceId
    INNER JOIN Teams t ON rr.constructorId = t.constructorId
    LEFT JOIN RaceStatus rs ON rr.statusId = rs.statusId
    WHERE rr.constructorId = @constructorId
      AND (@year IS NULL OR r.year = @year)
    GROUP BY r.year, t.name
    ORDER BY r.year DESC;
END
GO

-- ============================================
-- EXEMPLE DE UTILIZARE
-- ============================================

PRINT '============================================';
PRINT 'EXEMPLE DE UTILIZARE - BY NAME';
PRINT '============================================';
PRINT '';
PRINT '-- Inserare pilot nou: ';
PRINT 'EXEC sp_Driver_Insert @driverRef=''testdriver'', @forename=''Test'', @surname=''Driver'', @nationalityName=''British''';
PRINT '';
PRINT '-- Căutare pilot după nume:';
PRINT 'EXEC sp_Driver_GetByName @fullName=''Lewis Hamilton''';
PRINT 'EXEC sp_Driver_GetByName @surname=''Verstappen''';
PRINT '';
PRINT '-- Inserare rezultat cursă:';
PRINT 'EXEC sp_RaceResult_Insert @raceName=''British Grand Prix'', @raceYear=2023, @driverForename=''Lewis'', @driverSurname=''Hamilton'', @teamName=''Mercedes'', @positionOrder=1, @points=25';
PRINT '';
PRINT '-- Analiză strategie pit stop:';
PRINT 'EXEC sp_AnalyzeOptimalPitStrategy @circuitName=''Silverstone''';
PRINT 'EXEC sp_AnalyzeOptimalPitStrategy @circuitName=''Monaco''';
PRINT '';
PRINT '-- Analiză performanță pilot:';
PRINT 'EXEC sp_AnalyzeDriverSeasonPerformance @driverFullName=''Max Verstappen'', @year=2023';
PRINT '';
PRINT '-- Comparație piloți:';
PRINT 'EXEC sp_CompareDrivers @driver1FullName=''Lewis Hamilton'', @driver2FullName=''Max Verstappen''';
PRINT '';
PRINT '-- Analiză fiabilitate echipă:';
PRINT 'EXEC sp_AnalyzeTeamReliability @teamName=''Red Bull''';
PRINT '============================================';
GO