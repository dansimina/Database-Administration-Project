USE Formula1
GO

-- ============================================
-- PARTEA 1: PROCEDURI STOCATE CRUD DE BAZĂ
-- ============================================

-- =====================
-- CRUD pentru Drivers
-- =====================

-- CREATE
CREATE OR ALTER PROCEDURE sp_Driver_Insert
    @driverId INT,
    @driverRef VARCHAR(100),
    @number VARCHAR(3) = NULL,
    @code VARCHAR(3) = NULL,
    @forename VARCHAR(100),
    @surname VARCHAR(100),
    @dob DATE = NULL,
    @nationalityId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        INSERT INTO Drivers (driverId, driverRef, number, code, forename, surname, dob, nationalityId)
        VALUES (@driverId, @driverRef, @number, @code, @forename, @surname, @dob, @nationalityId);
        
        SELECT 'SUCCESS' AS Status, @driverId AS InsertedId;
    END TRY
    BEGIN CATCH
        SELECT 'ERROR' AS Status, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- READ (toate)
CREATE OR ALTER PROCEDURE sp_Driver_GetAll
AS
BEGIN
    SET NOCOUNT ON;
    SELECT d.*, n.nationalityName 
    FROM Drivers d
    LEFT JOIN Nationalities n ON d.nationalityId = n.nationalityId
    ORDER BY d.surname, d.forename;
END
GO

-- READ (după ID)
CREATE OR ALTER PROCEDURE sp_Driver_GetById
    @driverId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT d.*, n.nationalityName 
    FROM Drivers d
    LEFT JOIN Nationalities n ON d.nationalityId = n.nationalityId
    WHERE d.driverId = @driverId;
END
GO

-- UPDATE
CREATE OR ALTER PROCEDURE sp_Driver_Update
    @driverId INT,
    @driverRef VARCHAR(100) = NULL,
    @number VARCHAR(3) = NULL,
    @code VARCHAR(3) = NULL,
    @forename VARCHAR(100) = NULL,
    @surname VARCHAR(100) = NULL,
    @dob DATE = NULL,
    @nationalityId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        UPDATE Drivers
        SET driverRef = ISNULL(@driverRef, driverRef),
            number = ISNULL(@number, number),
            code = ISNULL(@code, code),
            forename = ISNULL(@forename, forename),
            surname = ISNULL(@surname, surname),
            dob = ISNULL(@dob, dob),
            nationalityId = ISNULL(@nationalityId, nationalityId)
        WHERE driverId = @driverId;
        
        SELECT 'SUCCESS' AS Status, @@ROWCOUNT AS RowsAffected;
    END TRY
    BEGIN CATCH
        SELECT 'ERROR' AS Status, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- DELETE
CREATE OR ALTER PROCEDURE sp_Driver_Delete
    @driverId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Verifică dacă există rezultate asociate
        IF EXISTS (SELECT 1 FROM RaceResults WHERE driverId = @driverId)
        BEGIN
            SELECT 'ERROR' AS Status, 'Cannot delete driver with existing race results' AS ErrorMessage;
            RETURN;
        END
        
        DELETE FROM Drivers WHERE driverId = @driverId;
        SELECT 'SUCCESS' AS Status, @@ROWCOUNT AS RowsDeleted;
    END TRY
    BEGIN CATCH
        SELECT 'ERROR' AS Status, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- =====================
-- CRUD pentru Teams
-- =====================

CREATE OR ALTER PROCEDURE sp_Team_Insert
    @constructorId INT,
    @constructorRef VARCHAR(100),
    @name VARCHAR(200),
    @nationalityId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO Teams (constructorId, constructorRef, name, nationalityId)
        VALUES (@constructorId, @constructorRef, @name, @nationalityId);
        SELECT 'SUCCESS' AS Status, @constructorId AS InsertedId;
    END TRY
    BEGIN CATCH
        SELECT 'ERROR' AS Status, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
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
    @constructorId INT,
    @constructorRef VARCHAR(100) = NULL,
    @name VARCHAR(200) = NULL,
    @nationalityId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Teams
    SET constructorRef = ISNULL(@constructorRef, constructorRef),
        name = ISNULL(@name, name),
        nationalityId = ISNULL(@nationalityId, nationalityId)
    WHERE constructorId = @constructorId;
    SELECT 'SUCCESS' AS Status, @@ROWCOUNT AS RowsAffected;
END
GO

CREATE OR ALTER PROCEDURE sp_Team_Delete
    @constructorId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM RaceResults WHERE constructorId = @constructorId)
    BEGIN
        SELECT 'ERROR' AS Status, 'Cannot delete team with existing race results' AS ErrorMessage;
        RETURN;
    END
    DELETE FROM Teams WHERE constructorId = @constructorId;
    SELECT 'SUCCESS' AS Status, @@ROWCOUNT AS RowsDeleted;
END
GO

-- =====================
-- CRUD pentru Races
-- =====================

CREATE OR ALTER PROCEDURE sp_Race_Insert
    @raceId INT,
    @year INT,
    @round INT,
    @circuitId INT,
    @name VARCHAR(200),
    @date DATE
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO Races (raceId, year, round, circuitId, name, date)
        VALUES (@raceId, @year, @round, @circuitId, @name, @date);
        SELECT 'SUCCESS' AS Status, @raceId AS InsertedId;
    END TRY
    BEGIN CATCH
        SELECT 'ERROR' AS Status, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE sp_Race_GetByYear
    @year INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT r.*, c. name AS circuitName, co.countryName
    FROM Races r
    INNER JOIN Circuits c ON r.circuitId = c.circuitId
    LEFT JOIN Countries co ON c.countryId = co.countryId
    WHERE r. year = @year
    ORDER BY r. round;
END
GO

-- =====================
-- CRUD pentru RaceResults
-- =====================

CREATE OR ALTER PROCEDURE sp_RaceResult_Insert
    @resultId INT,
    @raceId INT,
    @driverId INT,
    @constructorId INT,
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
    @statusId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO RaceResults 
        VALUES (@resultId, @raceId, @driverId, @constructorId, @grid, @position, 
                @positionOrder, @points, @laps, @time, @milliseconds, 
                @fastestLap, @fastestLapTime, @fastestLapSpeed, @statusId);
        SELECT 'SUCCESS' AS Status, @resultId AS InsertedId;
    END TRY
    BEGIN CATCH
        SELECT 'ERROR' AS Status, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- =====================
-- CRUD pentru PitStops
-- =====================

CREATE OR ALTER PROCEDURE sp_PitStop_Insert
    @raceId INT,
    @driverId INT,
    @stop INT,
    @lap INT,
    @duration VARCHAR(20) = NULL,
    @milliseconds INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO PitStops (raceId, driverId, stop, lap, duration, milliseconds)
        VALUES (@raceId, @driverId, @stop, @lap, @duration, @milliseconds);
        SELECT 'SUCCESS' AS Status;
    END TRY
    BEGIN CATCH
        SELECT 'ERROR' AS Status, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- ============================================
-- PARTEA 2: VEDERI (VIEWS)
-- ============================================

-- View 1: Clasament piloți pe sezon
CREATE OR ALTER VIEW vw_DriverStandingsBySeason
AS
SELECT 
    r.year AS Season,
    d. driverId,
    d.forename + ' ' + d. surname AS DriverName,
    d.code AS DriverCode,
    t.name AS TeamName,
    n. nationalityName AS Nationality,
    COUNT(DISTINCT rr.raceId) AS RacesParticipated,
    SUM(rr. points) AS TotalPoints,
    SUM(CASE WHEN rr.positionOrder = 1 THEN 1 ELSE 0 END) AS Wins,
    SUM(CASE WHEN rr.positionOrder <= 3 THEN 1 ELSE 0 END) AS Podiums,
    SUM(CASE WHEN rr.positionOrder <= 10 THEN 1 ELSE 0 END) AS PointsFinishes
FROM RaceResults rr
INNER JOIN Races r ON rr. raceId = r.raceId
INNER JOIN Drivers d ON rr.driverId = d.driverId
INNER JOIN Teams t ON rr.constructorId = t.constructorId
LEFT JOIN Nationalities n ON d.nationalityId = n.nationalityId
GROUP BY r.year, d.driverId, d.forename, d.surname, d.code, t. name, n.nationalityName
GO

-- View 2: Statistici circuite
CREATE OR ALTER VIEW vw_CircuitStatistics
AS
SELECT 
    c. circuitId,
    c.name AS CircuitName,
    ci.cityName AS City,
    co.countryName AS Country,
    COUNT(DISTINCT r.raceId) AS TotalRaces,
    MIN(r.year) AS FirstRaceYear,
    MAX(r.year) AS LastRaceYear,
    AVG(CAST(ps.stop AS FLOAT)) AS AvgPitStopsPerDriver
FROM Circuits c
LEFT JOIN Cities ci ON c.cityId = ci.cityId
LEFT JOIN Countries co ON c.countryId = co. countryId
LEFT JOIN Races r ON c. circuitId = r.circuitId
LEFT JOIN PitStops ps ON r. raceId = ps.raceId
GROUP BY c.circuitId, c. name, ci.cityName, co.countryName
GO

-- View 3: Performanță echipe per sezon
CREATE OR ALTER VIEW vw_TeamPerformanceBySeason
AS
SELECT 
    r.year AS Season,
    t.constructorId,
    t.name AS TeamName,
    n.nationalityName AS TeamNationality,
    COUNT(DISTINCT rr. driverId) AS NumberOfDrivers,
    COUNT(DISTINCT rr.raceId) AS RacesParticipated,
    SUM(rr. points) AS TotalPoints,
    SUM(CASE WHEN rr.positionOrder = 1 THEN 1 ELSE 0 END) AS Wins,
    SUM(CASE WHEN rr.positionOrder <= 3 THEN 1 ELSE 0 END) AS Podiums,
    CAST(AVG(CAST(rr.positionOrder AS FLOAT)) AS DECIMAL(5,2)) AS AvgFinishPosition
FROM RaceResults rr
INNER JOIN Races r ON rr.raceId = r.raceId
INNER JOIN Teams t ON rr. constructorId = t.constructorId
LEFT JOIN Nationalities n ON t.nationalityId = n.nationalityId
GROUP BY r.year, t.constructorId, t.name, n.nationalityName
GO

-- View 4: Detalii complete cursă
CREATE OR ALTER VIEW vw_RaceDetails
AS
SELECT 
    r. raceId,
    r.year AS Season,
    r.round,
    r.name AS RaceName,
    r.date AS RaceDate,
    c.name AS CircuitName,
    ci.cityName AS City,
    co. countryName AS Country,
    con.continentName AS Continent
FROM Races r
INNER JOIN Circuits c ON r.circuitId = c. circuitId
LEFT JOIN Cities ci ON c.cityId = ci.cityId
LEFT JOIN Countries co ON c.countryId = co.countryId
LEFT JOIN Continents con ON co.continentId = con.continentId
GO

-- View 5: Rezumat PitStops per cursă
CREATE OR ALTER VIEW vw_PitStopSummary
AS
SELECT 
    r.raceId,
    r.name AS RaceName,
    r.year AS Season,
    d.forename + ' ' + d.surname AS DriverName,
    t.name AS TeamName,
    COUNT(ps.stop) AS TotalStops,
    MIN(ps.milliseconds) AS FastestPitStop,
    MAX(ps.milliseconds) AS SlowestPitStop,
    AVG(ps.milliseconds) AS AvgPitStopTime
FROM PitStops ps
INNER JOIN Races r ON ps. raceId = r.raceId
INNER JOIN Drivers d ON ps. driverId = d. driverId
INNER JOIN RaceResults rr ON ps.raceId = rr.raceId AND ps.driverId = rr. driverId
INNER JOIN Teams t ON rr.constructorId = t.constructorId
GROUP BY r.raceId, r.name, r.year, d. forename, d. surname, t.name
GO

-- ============================================
-- PARTEA 3: FUNCȚII COMPLEXE DE ANALIZĂ
-- ============================================

-- =====================
-- FUNCȚIE 1: Strategia Optimă de PitStop pe Circuit
-- Analizează istoricul și determină câte opriri sunt optime
-- =====================

CREATE OR ALTER PROCEDURE sp_AnalyzeOptimalPitStrategy
    @circuitId INT,
    @topN INT = 10  -- Analizează doar primii N finisheri
AS
BEGIN
    SET NOCOUNT ON;
    
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
    
    -- Inserează datele de analiză
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
    GROUP BY r.year, r.name, d. forename, d. surname, rr. positionOrder;
    
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
    
    -- Rezultat 3: Detalii curse recente
    SELECT TOP 20
        RaceYear AS An,
        DriverName AS Pilot,
        FinishPosition AS Pozitie,
        TotalPitStops AS NrOpriri,
        TotalPitTime / 1000.0 AS TimpTotalPit_Secunde
    FROM #StrategyAnalysis
    ORDER BY RaceYear DESC, FinishPosition;
    
    DROP TABLE #StrategyAnalysis;
END
GO

-- =====================
-- FUNCȚIE 2: Evoluția Performanței Pilotului în Sezon
-- Arată cum fluctuează rezultatele de-a lungul sezonului
-- =====================

CREATE OR ALTER PROCEDURE sp_AnalyzeDriverSeasonPerformance
    @driverId INT,
    @year INT
AS
BEGIN
    SET NOCOUNT ON;
    
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
        rr. grid - rr.positionOrder AS PozitiiCastigate,
        SUM(rr.points) OVER (ORDER BY r.round) AS PuncteCumulate,
        AVG(CAST(rr. positionOrder AS FLOAT)) OVER (ORDER BY r.round ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS MediaPozitiiPanaAcum
    FROM Races r
    INNER JOIN RaceResults rr ON r.raceId = rr.raceId
    INNER JOIN Circuits c ON r.circuitId = c. circuitId
    INNER JOIN Teams t ON rr.constructorId = t. constructorId
    LEFT JOIN QualifyingResults q ON r.raceId = q. raceId AND rr.driverId = q.driverId
    LEFT JOIN RaceStatus rs ON rr. statusId = rs. statusId
    WHERE rr.driverId = @driverId AND r.year = @year
    ORDER BY r.round;
    
    -- Sumar sezon
    SELECT 
        'SUMAR SEZON ' + CAST(@year AS VARCHAR) AS Raport,
        d.forename + ' ' + d.surname AS Pilot,
        COUNT(*) AS CurseParticipate,
        SUM(rr.points) AS TotalPuncte,
        SUM(CASE WHEN rr.positionOrder = 1 THEN 1 ELSE 0 END) AS Victorii,
        SUM(CASE WHEN rr. positionOrder <= 3 THEN 1 ELSE 0 END) AS Podiumuri,
        SUM(CASE WHEN rr.positionOrder <= 10 THEN 1 ELSE 0 END) AS InPuncte,
        CAST(AVG(CAST(rr.positionOrder AS FLOAT)) AS DECIMAL(5,2)) AS PozitieFinishMedie,
        CAST(AVG(CAST(rr.grid AS FLOAT)) AS DECIMAL(5,2)) AS PozitieStartMedie,
        SUM(CASE WHEN rr.positionOrder < rr.grid THEN 1 ELSE 0 END) AS CurseCuPozitiiCastigate,
        SUM(rr.grid - rr.positionOrder) AS TotalPozitiiCastigate
    FROM RaceResults rr
    INNER JOIN Races r ON rr. raceId = r.raceId
    INNER JOIN Drivers d ON rr.driverId = d.driverId
    WHERE rr.driverId = @driverId AND r.year = @year
    GROUP BY d.forename, d.surname;
    
    -- Trend performanță (prima jumătate vs a doua jumătate de sezon)
    ;WITH SeasonHalves AS (
        SELECT 
            rr. driverId,
            CASE WHEN r.round <= (SELECT MAX(round)/2 FROM Races WHERE year = @year) 
                 THEN 'Prima Jumatate' ELSE 'A Doua Jumatate' END AS ParteSeason,
            rr.positionOrder,
            rr.points
        FROM RaceResults rr
        INNER JOIN Races r ON rr.raceId = r. raceId
        WHERE rr. driverId = @driverId AND r. year = @year
    )
    SELECT 
        ParteSeason,
        COUNT(*) AS Curse,
        SUM(points) AS Puncte,
        CAST(AVG(CAST(positionOrder AS FLOAT)) AS DECIMAL(5,2)) AS PozitieFinishMedie
    FROM SeasonHalves
    GROUP BY ParteSeason
    ORDER BY ParteSeason;
END
GO

-- =====================
-- FUNCȚIE 3: Comparație Directă între Doi Piloți
-- =====================

CREATE OR ALTER PROCEDURE sp_CompareDrivers
    @driver1Id INT,
    @driver2Id INT,
    @yearFrom INT = NULL,
    @yearTo INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Setează intervalul default
    SET @yearFrom = ISNULL(@yearFrom, 1950);
    SET @yearTo = ISNULL(@yearTo, 2025);
    
    -- Găsește cursele în care au participat amândoi
    ;WITH CommonRaces AS (
        SELECT DISTINCT rr1.raceId
        FROM RaceResults rr1
        INNER JOIN RaceResults rr2 ON rr1.raceId = rr2.raceId
        INNER JOIN Races r ON rr1.raceId = r. raceId
        WHERE rr1.driverId = @driver1Id 
          AND rr2.driverId = @driver2Id
          AND r.year BETWEEN @yearFrom AND @yearTo
    )
    
    -- Comparație head-to-head
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
    
    -- Detalii cursă cu cursă
    SELECT 
        r. year AS An,
        r.round AS Etapa,
        r.name AS Cursa,
        rr1.positionOrder AS PozPilot1,
        rr2.positionOrder AS PozPilot2,
        CASE 
            WHEN rr1.positionOrder < rr2.positionOrder THEN d1.surname
            WHEN rr2.positionOrder < rr1.positionOrder THEN d2.surname
            ELSE 'EGAL'
        END AS Castigator
    FROM RaceResults rr1
    INNER JOIN RaceResults rr2 ON rr1.raceId = rr2.raceId
    INNER JOIN Races r ON rr1.raceId = r.raceId
    INNER JOIN Drivers d1 ON rr1.driverId = d1.driverId
    INNER JOIN Drivers d2 ON rr2.driverId = d2.driverId
    WHERE rr1.driverId = @driver1Id 
      AND rr2.driverId = @driver2Id
      AND r. year BETWEEN @yearFrom AND @yearTo
    ORDER BY r.year, r.round;
END
GO

-- =====================
-- FUNCȚIE 4: Analiza Fiabilității Echipei
-- =====================

CREATE OR ALTER PROCEDURE sp_AnalyzeTeamReliability
    @constructorId INT,
    @year INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
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
    INNER JOIN Teams t ON rr. constructorId = t.constructorId
    LEFT JOIN RaceStatus rs ON rr.statusId = rs.statusId
    WHERE rr. constructorId = @constructorId
      AND (@year IS NULL OR r.year = @year)
    GROUP BY r.year, t.name
    ORDER BY r.year DESC;
    
    -- Tipuri de abandonuri
    SELECT 
        rs.statusName AS MotivAbandon,
        COUNT(*) AS Numar
    FROM RaceResults rr
    INNER JOIN Races r ON rr.raceId = r.raceId
    INNER JOIN RaceStatus rs ON rr.statusId = rs.statusId
    WHERE rr. constructorId = @constructorId
      AND rs.statusName != 'Finished'
      AND (@year IS NULL OR r.year = @year)
    GROUP BY rs.statusName
    ORDER BY COUNT(*) DESC;
END
GO

-- ============================================
-- PARTEA 4: TRIGGERE DML
-- ============================================

-- Tabelă pentru audit log
CREATE TABLE AuditLog (
    AuditId INT IDENTITY(1,1) PRIMARY KEY,
    TableName VARCHAR(100) NOT NULL,
    Operation VARCHAR(10) NOT NULL,
    RecordId VARCHAR(100) NOT NULL,
    OldValues NVARCHAR(MAX) NULL,
    NewValues NVARCHAR(MAX) NULL,
    ChangedBy VARCHAR(100) DEFAULT SYSTEM_USER,
    ChangedAt DATETIME DEFAULT GETDATE()
);
GO

-- Trigger 1: Audit pe Drivers (INSERT, UPDATE, DELETE)
CREATE OR ALTER TRIGGER trg_Drivers_Audit
ON Drivers
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- INSERT
    IF EXISTS(SELECT * FROM inserted) AND NOT EXISTS(SELECT * FROM deleted)
    BEGIN
        INSERT INTO AuditLog (TableName, Operation, RecordId, NewValues)
        SELECT 
            'Drivers', 
            'INSERT', 
            CAST(driverId AS VARCHAR),
            'DriverRef:  ' + driverRef + ', Name: ' + forename + ' ' + surname
        FROM inserted;
    END
    
    -- DELETE
    IF EXISTS(SELECT * FROM deleted) AND NOT EXISTS(SELECT * FROM inserted)
    BEGIN
        INSERT INTO AuditLog (TableName, Operation, RecordId, OldValues)
        SELECT 
            'Drivers', 
            'DELETE', 
            CAST(driverId AS VARCHAR),
            'DriverRef: ' + driverRef + ', Name: ' + forename + ' ' + surname
        FROM deleted;
    END
    
    -- UPDATE
    IF EXISTS(SELECT * FROM inserted) AND EXISTS(SELECT * FROM deleted)
    BEGIN
        INSERT INTO AuditLog (TableName, Operation, RecordId, OldValues, NewValues)
        SELECT 
            'Drivers', 
            'UPDATE', 
            CAST(i.driverId AS VARCHAR),
            'Name: ' + d.forename + ' ' + d.surname,
            'Name: ' + i.forename + ' ' + i.surname
        FROM inserted i
        INNER JOIN deleted d ON i. driverId = d.driverId;
    END
END
GO

-- Trigger 2: Validare RaceResults - punctele să fie corecte
CREATE OR ALTER TRIGGER trg_RaceResults_ValidatePoints
ON RaceResults
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verifică dacă punctele corespund poziției (sistem actual F1)
    IF EXISTS (
        SELECT 1 FROM inserted i
        WHERE i.positionOrder IS NOT NULL
        AND i.points IS NOT NULL
        AND (
            (i. positionOrder = 1 AND i. points NOT IN (25, 26)) OR  -- 26 pentru fastest lap
            (i. positionOrder = 2 AND i. points NOT IN (18, 19)) OR
            (i.positionOrder = 3 AND i.points NOT IN (15, 16)) OR
            (i.positionOrder > 10 AND i.points > 1)
        )
    )
    BEGIN
        PRINT 'Avertisment: Punctele pot să nu corespundă sistemului standard F1.'
    END
END
GO

-- Trigger 3: Actualizare automată - statistici după inserare rezultate
CREATE TABLE TeamSeasonStats (
    constructorId INT,
    year INT,
    totalPoints DECIMAL(10,2),
    totalWins INT,
    lastUpdated DATETIME,
    PRIMARY KEY (constructorId, year)
);
GO

CREATE OR ALTER TRIGGER trg_RaceResults_UpdateTeamStats
ON RaceResults
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Actualizează statisticile echipei
    MERGE TeamSeasonStats AS target
    USING (
        SELECT 
            i.constructorId,
            r.year,
            SUM(rr. points) AS totalPoints,
            SUM(CASE WHEN rr.positionOrder = 1 THEN 1 ELSE 0 END) AS totalWins
        FROM inserted i
        INNER JOIN Races r ON i. raceId = r.raceId
        INNER JOIN RaceResults rr ON rr.constructorId = i. constructorId 
            AND rr.raceId IN (SELECT raceId FROM Races WHERE year = r.year)
        GROUP BY i.constructorId, r. year
    ) AS source
    ON target.constructorId = source.constructorId AND target.year = source.year
    WHEN MATCHED THEN
        UPDATE SET 
            totalPoints = source.totalPoints,
            totalWins = source.totalWins,
            lastUpdated = GETDATE()
    WHEN NOT MATCHED THEN
        INSERT (constructorId, year, totalPoints, totalWins, lastUpdated)
        VALUES (source.constructorId, source.year, source.totalPoints, source.totalWins, GETDATE());
END
GO

-- ============================================
-- PARTEA 5: TRIGGER DDL
-- ============================================

-- Tabelă pentru DDL audit
CREATE TABLE DDLAuditLog (
    DDLAuditId INT IDENTITY(1,1) PRIMARY KEY,
    EventType VARCHAR(100),
    ObjectName VARCHAR(200),
    ObjectType VARCHAR(100),
    SQLCommand NVARCHAR(MAX),
    ExecutedBy VARCHAR(100) DEFAULT SYSTEM_USER,
    ExecutedAt DATETIME DEFAULT GETDATE()
);
GO

-- Trigger DDL la nivel de bază de date
CREATE OR ALTER TRIGGER trg_DDL_DatabaseAudit
ON DATABASE
FOR CREATE_TABLE, ALTER_TABLE, DROP_TABLE, 
    CREATE_PROCEDURE, ALTER_PROCEDURE, DROP_PROCEDURE,
    CREATE_VIEW, ALTER_VIEW, DROP_VIEW,
    CREATE_TRIGGER, ALTER_TRIGGER, DROP_TRIGGER
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @EventData XML = EVENTDATA();
    
    INSERT INTO DDLAuditLog (EventType, ObjectName, ObjectType, SQLCommand)
    VALUES (
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'VARCHAR(100)'),
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'VARCHAR(200)'),
        @EventData.value('(/EVENT_INSTANCE/ObjectType)[1]', 'VARCHAR(100)'),
        @EventData.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(MAX)')
    );
END
GO

-- ============================================
-- PARTEA 6: CURSOARE
-- ============================================

-- Procedură cu cursor:  Generare raport clasament sezon
CREATE OR ALTER PROCEDURE sp_GenerateSeasonStandingsReport
    @year INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @driverId INT, @driverName VARCHAR(200), @points DECIMAL(10,2);
    DECLARE @position INT = 0;
    
    -- Tabelă pentru raport
    CREATE TABLE #StandingsReport (
        Position INT,
        DriverName VARCHAR(200),
        TotalPoints DECIMAL(10,2),
        Status VARCHAR(50)
    );
    
    -- Cursor pentru clasament
    DECLARE driver_cursor CURSOR FOR
        SELECT 
            rr.driverId,
            d.forename + ' ' + d.surname AS DriverName,
            SUM(rr.points) AS TotalPoints
        FROM RaceResults rr
        INNER JOIN Races r ON rr. raceId = r.raceId
        INNER JOIN Drivers d ON rr.driverId = d.driverId
        WHERE r. year = @year
        GROUP BY rr.driverId, d.forename, d.surname
        ORDER BY SUM(rr. points) DESC;
    
    OPEN driver_cursor;
    
    FETCH NEXT FROM driver_cursor INTO @driverId, @driverName, @points;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @position = @position + 1;
        
        INSERT INTO #StandingsReport (Position, DriverName, TotalPoints, Status)
        VALUES (
            @position, 
            @driverName, 
            @points,
            CASE 
                WHEN @position = 1 THEN 'CAMPION'
                WHEN @position <= 3 THEN 'PODIUM'
                WHEN @position <= 10 THEN 'TOP 10'
                ELSE 'PARTICIPANT'
            END
        );
        
        FETCH NEXT FROM driver_cursor INTO @driverId, @driverName, @points;
    END
    
    CLOSE driver_cursor;
    DEALLOCATE driver_cursor;
    
    -- Afișează raportul
    SELECT * FROM #StandingsReport;
    
    DROP TABLE #StandingsReport;
END
GO

-- Procedură cu cursor:  Calculează gap-ul față de lider pentru fiecare cursă
CREATE OR ALTER PROCEDURE sp_CalculateChampionshipGaps
    @year INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @raceId INT, @raceName VARCHAR(200), @round INT;
    
    CREATE TABLE #ChampionshipProgress (
        Round INT,
        RaceName VARCHAR(200),
        DriverName VARCHAR(200),
        PointsAfterRace DECIMAL(10,2),
        GapToLeader DECIMAL(10,2)
    );
    
    -- Cursor pentru fiecare cursă din sezon
    DECLARE race_cursor CURSOR FOR
        SELECT raceId, name, round
        FROM Races
        WHERE year = @year
        ORDER BY round;
    
    OPEN race_cursor;
    FETCH NEXT FROM race_cursor INTO @raceId, @raceName, @round;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Pentru fiecare cursă, calculează punctele cumulate și gap-ul
        ;WITH CumulativePoints AS (
            SELECT 
                rr. driverId,
                d.forename + ' ' + d.surname AS DriverName,
                SUM(rr. points) AS TotalPoints
            FROM RaceResults rr
            INNER JOIN Races r ON rr.raceId = r. raceId
            INNER JOIN Drivers d ON rr. driverId = d.driverId
            WHERE r.year = @year AND r.round <= @round
            GROUP BY rr. driverId, d. forename, d. surname
        ),
        LeaderPoints AS (
            SELECT MAX(TotalPoints) AS MaxPoints FROM CumulativePoints
        )
        INSERT INTO #ChampionshipProgress
        SELECT 
            @round,
            @raceName,
            cp.DriverName,
            cp.TotalPoints,
            lp.MaxPoints - cp.TotalPoints
        FROM CumulativePoints cp
        CROSS JOIN LeaderPoints lp
        WHERE cp. TotalPoints >= (SELECT MAX(TotalPoints) * 0.5 FROM CumulativePoints); -- Doar cei relevanți
        
        FETCH NEXT FROM race_cursor INTO @raceId, @raceName, @round;
    END
    
    CLOSE race_cursor;
    DEALLOCATE race_cursor;
    
    SELECT * FROM #ChampionshipProgress ORDER BY Round, GapToLeader;
    
    DROP TABLE #ChampionshipProgress;
END
GO

-- ============================================
-- PARTEA 7: UTILIZATORI ȘI ROLURI
-- ============================================

-- Creare Login-uri (la nivel de server)
USE master;
GO

-- Verifică și creează login-uri
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'F1_Admin')
    CREATE LOGIN F1_Admin WITH PASSWORD = 'Admin@F1_2024! ';
GO

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'F1_Analyst')
    CREATE LOGIN F1_Analyst WITH PASSWORD = 'Analyst@F1_2024!';
GO

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'F1_Reporter')
    CREATE LOGIN F1_Reporter WITH PASSWORD = 'Reporter@F1_2024!';
GO

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'F1_DataEntry')
    CREATE LOGIN F1_DataEntry WITH PASSWORD = 'DataEntry@F1_2024!';
GO

USE Formula1;
GO

-- Creare Utilizatori în baza de date
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'F1_Admin')
    CREATE USER F1_Admin FOR LOGIN F1_Admin;
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'F1_Analyst')
    CREATE USER F1_Analyst FOR LOGIN F1_Analyst;
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'F1_Reporter')
    CREATE USER F1_Reporter FOR LOGIN F1_Reporter;
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'F1_DataEntry')
    CREATE USER F1_DataEntry FOR LOGIN F1_DataEntry;
GO

-- Creare Roluri
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Role_F1_FullAccess')
    CREATE ROLE Role_F1_FullAccess;
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Role_F1_Analysis')
    CREATE ROLE Role_F1_Analysis;
GO

IF NOT EXISTS (SELECT * FROM sys. database_principals WHERE name = 'Role_F1_ReadOnly')
    CREATE ROLE Role_F1_ReadOnly;
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Role_F1_DataEntry')
    CREATE ROLE Role_F1_DataEntry;
GO

-- Atribuire drepturi rolurilor

-- Role_F1_FullAccess:  Acces complet
GRANT CONTROL ON DATABASE:: Formula1 TO Role_F1_FullAccess;
GO

-- Role_F1_Analysis:  Citire + executare proceduri de analiză
GRANT SELECT ON SCHEMA:: dbo TO Role_F1_Analysis;
GRANT EXECUTE ON sp_AnalyzeOptimalPitStrategy TO Role_F1_Analysis;
GRANT EXECUTE ON sp_AnalyzeDriverSeasonPerformance TO Role_F1_Analysis;
GRANT EXECUTE ON sp_CompareDrivers TO Role_F1_Analysis;
GRANT EXECUTE ON sp_AnalyzeTeamReliability TO Role_F1_Analysis;
GRANT EXECUTE ON sp_GenerateSeasonStandingsReport TO Role_F1_Analysis;
GRANT EXECUTE ON sp_CalculateChampionshipGaps TO Role_F1_Analysis;
GO

-- Role_F1_ReadOnly:  Doar citire views și tabele
GRANT SELECT ON SCHEMA:: dbo TO Role_F1_ReadOnly;
GO

-- Role_F1_DataEntry:  Poate insera/actualiza date
GRANT SELECT ON SCHEMA:: dbo TO Role_F1_DataEntry;
GRANT EXECUTE ON sp_Driver_Insert TO Role_F1_DataEntry;
GRANT EXECUTE ON sp_Driver_Update TO Role_F1_DataEntry;
GRANT EXECUTE ON sp_Team_Insert TO Role_F1_DataEntry;
GRANT EXECUTE ON sp_Team_Update TO Role_F1_DataEntry;
GRANT EXECUTE ON sp_Race_Insert TO Role_F1_DataEntry;
GRANT EXECUTE ON sp_RaceResult_Insert TO Role_F1_DataEntry;
GRANT EXECUTE ON sp_PitStop_Insert TO Role_F1_DataEntry;
-- NU are dreptul de DELETE
GO

-- Atribuire utilizatori la roluri
ALTER ROLE Role_F1_FullAccess ADD MEMBER F1_Admin;
ALTER ROLE Role_F1_Analysis ADD MEMBER F1_Analyst;
ALTER ROLE Role_F1_ReadOnly ADD MEMBER F1_Reporter;
ALTER ROLE Role_F1_DataEntry ADD MEMBER F1_DataEntry;
GO

-- ============================================
-- PARTEA 8: JOBURI SQL SERVER AGENT
-- ============================================

USE msdb;
GO

-- Job 1: Backup zilnic
IF EXISTS (SELECT * FROM sysjobs WHERE name = 'F1_Daily_Backup')
    EXEC sp_delete_job @job_name = 'F1_Daily_Backup';
GO

EXEC sp_add_job 
    @job_name = 'F1_Daily_Backup',
    @enabled = 1,
    @description = 'Backup zilnic al bazei de date Formula1';
GO

EXEC sp_add_jobstep
    @job_name = 'F1_Daily_Backup',
    @step_name = 'Full Backup',
    @subsystem = 'TSQL',
    @command = N'
        DECLARE @BackupPath NVARCHAR(500);
        DECLARE @BackupName NVARCHAR(200);
        
        SET @BackupPath = ''C:\SQLBackups\Formula1_Full_'' + 
                          CONVERT(VARCHAR(8), GETDATE(), 112) + ''. bak'';
        SET @BackupName = ''Formula1 Full Backup '' + CONVERT(VARCHAR(20), GETDATE(), 120);
        
        BACKUP DATABASE Formula1 
        TO DISK = @BackupPath
        WITH FORMAT, 
             NAME = @BackupName,
             COMPRESSION,
             STATS = 10;',
    @database_name = 'master';
GO

EXEC sp_add_schedule
    @schedule_name = 'Daily_2AM',
    @freq_type = 4,  -- Daily
    @freq_interval = 1,
    @active_start_time = 020000;  -- 02:00:00
GO

EXEC sp_attach_schedule
    @job_name = 'F1_Daily_Backup',
    @schedule_name = 'Daily_2AM';
GO

EXEC sp_add_jobserver
    @job_name = 'F1_Daily_Backup',
    @server_name = '(LOCAL)';
GO

-- Job 2: Curățare log-uri vechi (săptămânal)
IF EXISTS (SELECT * FROM sysjobs WHERE name = 'F1_Cleanup_Old_Logs')
    EXEC sp_delete_job @job_name = 'F1_Cleanup_Old_Logs';
GO

EXEC sp_add_job 
    @job_name = 'F1_Cleanup_Old_Logs',
    @enabled = 1,
    @description = 'Sterge log-urile mai vechi de 90 de zile';
GO

EXEC sp_add_jobstep
    @job_name = 'F1_Cleanup_Old_Logs',
    @step_name = 'Delete Old Audit Logs',
    @subsystem = 'TSQL',
    @command = N'
        USE Formula1;
        
        -- Șterge audit logs mai vechi de 90 zile
        DELETE FROM AuditLog 
        WHERE ChangedAt < DATEADD(DAY, -90, GETDATE());
        
        DELETE FROM DDLAuditLog 
        WHERE ExecutedAt < DATEADD(DAY, -90, GETDATE());
        
        PRINT ''Cleanup completed:  '' + CONVERT(VARCHAR(20), GETDATE(), 120);',
    @database_name = 'Formula1';
GO

EXEC sp_add_schedule
    @schedule_name = 'Weekly_Sunday_3AM',
    @freq_type = 8,  -- Weekly
    @freq_interval = 1,  -- Sunday
    @freq_recurrence_factor = 1,
    @active_start_time = 030000;
GO

EXEC sp_attach_schedule
    @job_name = 'F1_Cleanup_Old_Logs',
    @schedule_name = 'Weekly_Sunday_3AM';
GO

EXEC sp_add_jobserver
    @job_name = 'F1_Cleanup_Old_Logs',
    @server_name = '(LOCAL)';
GO

-- Job 3: Actualizare statistici echipe
IF EXISTS (SELECT * FROM sysjobs WHERE name = 'F1_Update_Team_Stats')
    EXEC sp_delete_job @job_name = 'F1_Update_Team_Stats';
GO

EXEC sp_add_job 
    @job_name = 'F1_Update_Team_Stats',
    @enabled = 1,
    @description = 'Actualizează statisticile echipelor zilnic';
GO

EXEC sp_add_jobstep
    @job_name = 'F1_Update_Team_Stats',
    @step_name = 'Refresh Team Statistics',
    @subsystem = 'TSQL',
    @command = N'
        USE Formula1;
        
        -- Recalculează toate statisticile echipelor
        MERGE TeamSeasonStats AS target
        USING (
            SELECT 
                rr.constructorId,
                r.year,
                SUM(rr.points) AS totalPoints,
                SUM(CASE WHEN rr. positionOrder = 1 THEN 1 ELSE 0 END) AS totalWins
            FROM RaceResults rr
            INNER JOIN Races r ON rr.raceId = r. raceId
            GROUP BY rr.constructorId, r. year
        ) AS source
        ON target.constructorId = source.constructorId AND target.year = source.year
        WHEN MATCHED THEN
            UPDATE SET 
                totalPoints = source.totalPoints,
                totalWins = source.totalWins,
                lastUpdated = GETDATE()
        WHEN NOT MATCHED THEN
            INSERT (constructorId, year, totalPoints, totalWins, lastUpdated)
            VALUES (source. constructorId, source.year, source. totalPoints, source. totalWins, GETDATE());',
    @database_name = 'Formula1';
GO

EXEC sp_attach_schedule
    @job_name = 'F1_Update_Team_Stats',
    @schedule_name = 'Daily_2AM';
GO

EXEC sp_add_jobserver
    @job_name = 'F1_Update_Team_Stats',
    @server_name = '(LOCAL)';
GO

USE Formula1;
GO

-- ============================================
-- PARTEA 9: STRATEGII DE BACKUP/RESTORE
-- ============================================

-- Procedură pentru Full Backup
CREATE OR ALTER PROCEDURE sp_Backup_Full
    @BackupPath NVARCHAR(500) = 'C:\SQLBackups\'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @BackupFile NVARCHAR(500);
    DECLARE @BackupName NVARCHAR(200);
    
    SET @BackupFile = @BackupPath + 'Formula1_Full_' + 
                      CONVERT(VARCHAR(8), GETDATE(), 112) + '_' +
                      REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), ':', '') + '.bak';
    SET @BackupName = 'Formula1 Full Backup ' + CONVERT(VARCHAR(20), GETDATE(), 120);
    
    BACKUP DATABASE Formula1 
    TO DISK = @BackupFile
    WITH FORMAT, 
         INIT,
         NAME = @BackupName,
         COMPRESSION,
         STATS = 10,
         CHECKSUM;
    
    -- Verifică backup-ul
    RESTORE VERIFYONLY FROM DISK = @BackupFile;
    
    SELECT 'Full Backup Completed' AS Status, @BackupFile AS BackupFile, GETDATE() AS CompletedAt;
END
GO

-- Procedură pentru Differential Backup
CREATE OR ALTER PROCEDURE sp_Backup_Differential
    @BackupPath NVARCHAR(500) = 'C:\SQLBackups\'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @BackupFile NVARCHAR(500);
    
    SET @BackupFile = @BackupPath + 'Formula1_Diff_' + 
                      CONVERT(VARCHAR(8), GETDATE(), 112) + '_' +
                      REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), ':', '') + '.bak';
    
    BACKUP DATABASE Formula1 
    TO DISK = @BackupFile
    WITH DIFFERENTIAL, 
         COMPRESSION,
         STATS = 10,
         CHECKSUM;
    
    SELECT 'Differential Backup Completed' AS Status, @BackupFile AS BackupFile;
END
GO

-- Procedură pentru Transaction Log Backup
CREATE OR ALTER PROCEDURE sp_Backup_TransactionLog
    @BackupPath NVARCHAR(500) = 'C:\SQLBackups\'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @BackupFile NVARCHAR(500);
    
    SET @BackupFile = @BackupPath + 'Formula1_Log_' + 
                      CONVERT(VARCHAR(8), GETDATE(), 112) + '_' +
                      REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), ':', '') + '.trn';
    
    BACKUP LOG Formula1 
    TO DISK = @BackupFile
    WITH COMPRESSION,
         STATS = 10;
    
    SELECT 'Transaction Log Backup Completed' AS Status, @BackupFile AS BackupFile;
END
GO

-- Procedură pentru Restore complet
CREATE OR ALTER PROCEDURE sp_Restore_Full
    @FullBackupFile NVARCHAR(500),
    @DiffBackupFile NVARCHAR(500) = NULL,
    @NewDatabaseName NVARCHAR(100) = 'Formula1_Restored'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @DataFile NVARCHAR(500) = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\' + @NewDatabaseName + '.mdf';
    DECLARE @LogFile NVARCHAR(500) = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\' + @NewDatabaseName + '_log.ldf';
    
    -- Restore full backup
    IF @DiffBackupFile IS NULL
    BEGIN
        RESTORE DATABASE @NewDatabaseName
        FROM DISK = @FullBackupFile
        WITH MOVE 'Formula1' TO @DataFile,
             MOVE 'Formula1_log' TO @LogFile,
             REPLACE,
             RECOVERY,
             STATS = 10;
    END
    ELSE
    BEGIN
        -- Restore full cu NORECOVERY apoi differential
        RESTORE DATABASE @NewDatabaseName
        FROM DISK = @FullBackupFile
        WITH MOVE 'Formula1' TO @DataFile,
             MOVE 'Formula1_log' TO @LogFile,
             REPLACE,
             NORECOVERY,
             STATS = 10;
        
        RESTORE DATABASE @NewDatabaseName
        FROM DISK = @DiffBackupFile
        WITH RECOVERY,
             STATS = 10;
    END
    
    SELECT 'Restore Completed' AS Status, @NewDatabaseName AS RestoredAs;
END
GO

-- ============================================
-- PARTEA 10: PROCEDURĂ DE VERIFICARE COMPLETĂ
-- ============================================

CREATE OR ALTER PROCEDURE sp_VerifyDatabaseRequirements
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '========================================';
    PRINT 'VERIFICARE CERINȚE PROIECT FORMULA1';
    PRINT '========================================';
    PRINT '';
    
    -- 1. Tabele
    PRINT '1. TABELE (cerință:  8-10):';
    SELECT COUNT(*) AS NumarTabele FROM sys.tables WHERE type = 'U';
    SELECT name AS NumeTabel FROM sys.tables WHERE type = 'U' ORDER BY name;
    PRINT '';
    
    -- 2. Relații
    PRINT '2. RELAȚII FOREIGN KEY:';
    SELECT 
        fk.name AS FK_Name,
        tp.name AS ParentTable,
        tr.name AS ReferencedTable
    FROM sys.foreign_keys fk
    INNER JOIN sys.tables tp ON fk.parent_object_id = tp. object_id
    INNER JOIN sys. tables tr ON fk.referenced_object_id = tr.object_id;
    PRINT '';
    
    -- 3. Constrângeri
    PRINT '3. CONSTRÂNGERI:';
    SELECT 
        type_desc AS TipConstrangere,
        COUNT(*) AS Numar
    FROM sys.objects 
    WHERE type IN ('PK', 'UQ', 'F', 'C', 'D')
    GROUP BY type_desc;
    PRINT '';
    
    -- 4. Indecși
    PRINT '4. INDECȘI:';
    SELECT 
        t.name AS Tabel,
        i.name AS NumeIndex,
        i. type_desc AS TipIndex,
        i.is_unique AS EsteUnique
    FROM sys.indexes i
    INNER JOIN sys.tables t ON i.object_id = t.object_id
    WHERE i.name IS NOT NULL
    ORDER BY t.name, i. name;
    PRINT '';
    
    -- 5. Vederi
    PRINT '5. VEDERI (VIEWS):';
    SELECT name AS NumeView FROM sys.views ORDER BY name;
    PRINT '';
    
    -- 6. Proceduri stocate
    PRINT '6. PROCEDURI STOCATE:';
    SELECT name AS NumeProcedura FROM sys.procedures ORDER BY name;
    PRINT '';
    
    -- 7. Triggere DML
    PRINT '7. TRIGGERE DML:';
    SELECT 
        t.name AS Trigger_Name,
        OBJECT_NAME(t. parent_id) AS TableName,
        t.type_desc
    FROM sys.triggers t
    WHERE t.parent_class = 1;
    PRINT '';
    
    -- 8. Triggere DDL
    PRINT '8. TRIGGERE DDL:';
    SELECT name, type_desc FROM sys.triggers WHERE parent_class = 0;
    PRINT '';
    
    -- 9. Utilizatori și Roluri
    PRINT '9. UTILIZATORI ȘI ROLURI:';
    SELECT name AS NumeUser, type_desc AS Tip FROM sys.database_principals 
    WHERE type IN ('S', 'U', 'R') AND name NOT LIKE '##%' AND name NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys', 'public')
    ORDER BY type_desc, name;
    PRINT '';
    
    PRINT '========================================';
    PRINT 'VERIFICARE COMPLETĂ! ';
    PRINT '========================================';
END
GO

-- Execută verificarea
EXEC sp_VerifyDatabaseRequirements;
GO