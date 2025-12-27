USE Formula1;
GO

-- ============================================
-- PARTEA 1: ADĂUGARE COLOANE NOI ÎN DRIVERS
-- ============================================

-- Adaugă coloana pentru numărul de victorii
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Drivers') AND name = 'totalWins')
BEGIN
    ALTER TABLE Drivers ADD totalWins INT DEFAULT 0;
    PRINT 'Coloana totalWins a fost adăugată. ';
END
GO

-- Adaugă coloana pentru numărul de pole positions
IF NOT EXISTS (SELECT * FROM sys. columns WHERE object_id = OBJECT_ID('Drivers') AND name = 'totalPolePositions')
BEGIN
    ALTER TABLE Drivers ADD totalPolePositions INT DEFAULT 0;
    PRINT 'Coloana totalPolePositions a fost adăugată.';
END
GO

-- ============================================
-- PARTEA 2: POPULARE INIȚIALĂ A DATELOR
-- ============================================

-- Actualizează victoriile existente (position = 1 în RaceResults)
UPDATE d
SET d.totalWins = ISNULL(wins. WinCount, 0)
FROM Drivers d
LEFT JOIN (
    SELECT driverId, COUNT(*) AS WinCount
    FROM RaceResults
    WHERE positionOrder = 1
    GROUP BY driverId
) wins ON d.driverId = wins.driverId;

PRINT 'Victoriile au fost actualizate pentru toți piloții.';
GO

-- Actualizează pole positions existente (position = 1 în QualifyingResults)
UPDATE d
SET d.totalPolePositions = ISNULL(poles.PoleCount, 0)
FROM Drivers d
LEFT JOIN (
    SELECT driverId, COUNT(*) AS PoleCount
    FROM QualifyingResults
    WHERE position = 1
    GROUP BY driverId
) poles ON d.driverId = poles.driverId;

PRINT 'Pole positions au fost actualizate pentru toți piloții.';
GO

-- Verificare rapidă
SELECT TOP 10
    driverId,
    forename + ' ' + surname AS DriverName,
    totalWins,
    totalPolePositions
FROM Drivers
WHERE totalWins > 0 OR totalPolePositions > 0
ORDER BY totalWins DESC;
GO

-- ============================================
-- PARTEA 3: TRIGGER PENTRU ACTUALIZARE VICTORII
-- ============================================

CREATE OR ALTER TRIGGER trg_RaceResults_UpdateDriverWins
ON RaceResults
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Colectează toți piloții afectați
    DECLARE @AffectedDrivers TABLE (driverId INT);
    
    -- Piloți din rândurile inserate
    INSERT INTO @AffectedDrivers (driverId)
    SELECT DISTINCT driverId FROM inserted;
    
    -- Piloți din rândurile șterse
    INSERT INTO @AffectedDrivers (driverId)
    SELECT DISTINCT driverId FROM deleted
    WHERE driverId NOT IN (SELECT driverId FROM @AffectedDrivers);
    
    -- Recalculează victoriile pentru piloții afectați
    UPDATE d
    SET d.totalWins = ISNULL(wins.WinCount, 0)
    FROM Drivers d
    INNER JOIN @AffectedDrivers ad ON d.driverId = ad. driverId
    LEFT JOIN (
        SELECT driverId, COUNT(*) AS WinCount
        FROM RaceResults
        WHERE positionOrder = 1
        GROUP BY driverId
    ) wins ON d.driverId = wins.driverId;
    
    -- Log pentru audit (opțional)
    IF EXISTS (SELECT * FROM sys.tables WHERE name = 'AuditLog')
    BEGIN
        INSERT INTO AuditLog (TableName, Operation, RecordId, NewValues)
        SELECT 
            'Drivers',
            'AUTO_UPDATE_WINS',
            CAST(driverId AS VARCHAR),
            'Wins recalculated via trigger'
        FROM @AffectedDrivers;
    END
END
GO

PRINT 'Trigger trg_RaceResults_UpdateDriverWins creat cu succes. ';
GO

-- ============================================
-- PARTEA 4: TRIGGER PENTRU ACTUALIZARE POLE POSITIONS
-- ============================================

CREATE OR ALTER TRIGGER trg_QualifyingResults_UpdateDriverPoles
ON QualifyingResults
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Colectează toți piloții afectați
    DECLARE @AffectedDrivers TABLE (driverId INT);
    
    -- Piloți din rândurile inserate
    INSERT INTO @AffectedDrivers (driverId)
    SELECT DISTINCT driverId FROM inserted;
    
    -- Piloți din rândurile șterse
    INSERT INTO @AffectedDrivers (driverId)
    SELECT DISTINCT driverId FROM deleted
    WHERE driverId NOT IN (SELECT driverId FROM @AffectedDrivers);
    
    -- Recalculează pole positions pentru piloții afectați
    UPDATE d
    SET d.totalPolePositions = ISNULL(poles. PoleCount, 0)
    FROM Drivers d
    INNER JOIN @AffectedDrivers ad ON d.driverId = ad. driverId
    LEFT JOIN (
        SELECT driverId, COUNT(*) AS PoleCount
        FROM QualifyingResults
        WHERE position = 1
        GROUP BY driverId
    ) poles ON d.driverId = poles.driverId;
    
    -- Log pentru audit (opțional)
    IF EXISTS (SELECT * FROM sys.tables WHERE name = 'AuditLog')
    BEGIN
        INSERT INTO AuditLog (TableName, Operation, RecordId, NewValues)
        SELECT 
            'Drivers',
            'AUTO_UPDATE_POLES',
            CAST(driverId AS VARCHAR),
            'Pole positions recalculated via trigger'
        FROM @AffectedDrivers;
    END
END
GO

PRINT 'Trigger trg_QualifyingResults_UpdateDriverPoles creat cu succes.';
GO

-- ============================================
-- PARTEA 5: TESTARE TRIGGERE
-- ============================================

-- Verifică un pilot înainte de test
DECLARE @testDriverId INT = (SELECT TOP 1 driverId FROM Drivers);

SELECT 'ÎNAINTE DE TEST' AS Status, driverId, forename, surname, totalWins, totalPolePositions 
FROM Drivers WHERE driverId = @testDriverId;

-- Simulează o victorie nouă (și apoi o șterge)
DECLARE @testRaceId INT = (SELECT TOP 1 raceId FROM Races ORDER BY raceId DESC);
DECLARE @testConstructorId INT = (SELECT TOP 1 constructorId FROM Teams);
DECLARE @newResultId INT = (SELECT ISNULL(MAX(resultId), 0) + 1 FROM RaceResults);

-- Insert rezultat cu victorie
INSERT INTO RaceResults (resultId, raceId, driverId, constructorId, positionOrder, points)
VALUES (@newResultId, @testRaceId, @testDriverId, @testConstructorId, 1, 25);

SELECT 'DUPĂ INSERT VICTORIE' AS Status, driverId, forename, surname, totalWins, totalPolePositions 
FROM Drivers WHERE driverId = @testDriverId;

-- Șterge rezultatul de test
DELETE FROM RaceResults WHERE resultId = @newResultId;

SELECT 'DUPĂ DELETE' AS Status, driverId, forename, surname, totalWins, totalPolePositions 
FROM Drivers WHERE driverId = @testDriverId;

PRINT 'Testare triggere completă! ';
GO

-- ============================================
-- PARTEA 6: VIEW ACTUALIZAT CU NOILE COLOANE
-- ============================================

CREATE OR ALTER VIEW vw_DriverCareerStats
AS
SELECT 
    d.driverId,
    d.code AS DriverCode,
    d.forename + ' ' + d. surname AS FullName,
    d. dob AS DateOfBirth,
    DATEDIFF(YEAR, d.dob, GETDATE()) AS Age,
    n.nationalityName AS Nationality,
    d.totalWins,
    d.totalPolePositions,
    COUNT(DISTINCT rr.raceId) AS TotalRaces,
    SUM(rr. points) AS TotalCareerPoints,
    SUM(CASE WHEN rr.positionOrder <= 3 THEN 1 ELSE 0 END) AS TotalPodiums,
    MIN(r.year) AS FirstSeasonYear,
    MAX(r.year) AS LastSeasonYear,
    MAX(r.year) - MIN(r.year) + 1 AS SeasonsActive
FROM Drivers d
LEFT JOIN Nationalities n ON d. nationalityId = n.nationalityId
LEFT JOIN RaceResults rr ON d. driverId = rr.driverId
LEFT JOIN Races r ON rr.raceId = r.raceId
GROUP BY d.driverId, d.code, d.forename, d.surname, d.dob, n.nationalityName, d.totalWins, d.totalPolePositions;
GO

-- Verificare view
SELECT TOP 15 * FROM vw_DriverCareerStats ORDER BY totalWins DESC;
GO

-- ============================================
-- PARTEA 7: PROCEDURĂ PENTRU RECALCULARE MANUALĂ
-- ============================================

CREATE OR ALTER PROCEDURE sp_RecalculateDriverStats
    @driverId INT = NULL  -- NULL = recalculează pentru toți
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Recalculează victoriile
    UPDATE d
    SET d.totalWins = ISNULL(wins.WinCount, 0)
    FROM Drivers d
    LEFT JOIN (
        SELECT driverId, COUNT(*) AS WinCount
        FROM RaceResults
        WHERE positionOrder = 1
        GROUP BY driverId
    ) wins ON d.driverId = wins.driverId
    WHERE @driverId IS NULL OR d.driverId = @driverId;
    
    -- Recalculează pole positions
    UPDATE d
    SET d.totalPolePositions = ISNULL(poles. PoleCount, 0)
    FROM Drivers d
    LEFT JOIN (
        SELECT driverId, COUNT(*) AS PoleCount
        FROM QualifyingResults
        WHERE position = 1
        GROUP BY driverId
    ) poles ON d.driverId = poles.driverId
    WHERE @driverId IS NULL OR d.driverId = @driverId;
    
    -- Afișează rezultatele
    SELECT 
        driverId,
        forename + ' ' + surname AS DriverName,
        totalWins,
        totalPolePositions
    FROM Drivers
    WHERE (@driverId IS NULL OR driverId = @driverId)
      AND (totalWins > 0 OR totalPolePositions > 0)
    ORDER BY totalWins DESC, totalPolePositions DESC;
    
    SELECT 'Recalculare completă!' AS Status, 
           CASE WHEN @driverId IS NULL THEN 'Toți piloții' ELSE 'Pilot ID: ' + CAST(@driverId AS VARCHAR) END AS Scope;
END
GO

-- Test procedură
-- EXEC sp_RecalculateDriverStats;  -- Pentru toți
-- EXEC sp_RecalculateDriverStats @driverId = 1;  -- Pentru un pilot specific
GO

PRINT '============================================';
PRINT 'IMPLEMENTARE COMPLETĂ! ';
PRINT '============================================';
PRINT 'Coloane adăugate:  totalWins, totalPolePositions';
PRINT 'Triggere create: trg_RaceResults_UpdateDriverWins, trg_QualifyingResults_UpdateDriverPoles';
PRINT 'View creat: vw_DriverCareerStats';
PRINT 'Procedură:  sp_RecalculateDriverStats';
PRINT '============================================';
GO