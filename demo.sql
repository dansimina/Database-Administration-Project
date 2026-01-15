-- ============================================================
-- DEMO PREZENTARE - BAZA DE DATE FORMULA 1
-- ============================================================

USE [Formula1];

-- ============================================================
-- SECȚIUNEA 1: STRUCTURA BAZEI DE DATE
-- Testare:  Tabele, relații 1-n și m-n
-- ============================================================

SELECT TOP 5 * FROM Drivers ORDER BY totalWins DESC, totalPolePositions DESC;
SELECT TOP 5 * FROM Teams;
SELECT TOP 5 * FROM Circuits;
SELECT TOP 5 * FROM RaceResults;
SELECT TOP 5 * FROM QualifyingResults;
SELECT TOP 5 * FROM PitStops;
SELECT TOP 5 * FROM Cities;
SELECT TOP 5 * FROM Countries;

-- Test 1.1: Relație 1-n (Countries -> Cities)
SELECT 
    co.countryName AS Tara,
    COUNT(ci.cityId) AS NumarOrase
FROM Countries co
LEFT JOIN Cities ci ON co.countryId = ci.countryId
GROUP BY co.countryName
HAVING COUNT(ci.cityId) > 0
ORDER BY COUNT(ci.cityId) DESC;

-- Test 1.2: Relație m-n (Drivers <-> Teams prin DriverContracts)
SELECT TOP 5
    d.forename + ' ' + d.surname AS Pilot,
    COUNT(DISTINCT dc.constructorId) AS NumarEchipe
FROM Drivers d
INNER JOIN DriverContracts dc ON d.driverId = dc.driverId
GROUP BY d.driverId, d.forename, d.surname
HAVING COUNT(DISTINCT dc.constructorId) > 1
ORDER BY COUNT(DISTINCT dc.constructorId) DESC;

-- ============================================================
-- SECȚIUNEA 2: CONSTRÂNGERI ȘI INDECȘI
-- Testare:  UNIQUE constraints, Clustered/Non-clustered indexes
-- ============================================================

-- Test 2.1: Afișare constrângeri UNIQUE
SELECT 
    TABLE_NAME AS Tabela,
    CONSTRAINT_NAME AS Constrangere
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE CONSTRAINT_TYPE = 'UNIQUE'
ORDER BY TABLE_NAME;

-- Test 2.2: Afișare indecși
SELECT 
    OBJECT_NAME(i.object_id) AS Tabela,
    i.name AS NumeIndex,
    i.type_desc AS TipIndex
FROM sys.indexes i
WHERE OBJECT_SCHEMA_NAME(i.object_id) = 'dbo'
  AND i.name IS NOT NULL
  AND OBJECT_NAME(i.object_id) IN ('Drivers', 'Teams', 'Races')
ORDER BY Tabela;

-- ============================================================
-- SECȚIUNEA 3: VEDERI (VIEWS)
-- ============================================================

-- Test 3.1: vw_CircuitStatistics
SELECT *
FROM vw_CircuitStatistics
WHERE TotalRaces > 0
ORDER BY TotalRaces DESC;

-- Test 3.2: vw_DriverCareerStats
SELECT *
FROM vw_DriverCareerStats
WHERE TotalCareerPoints > 0
ORDER BY TotalCareerPoints DESC;

-- Test 3.3: vw_DriverStandingsBySeason
SELECT *
FROM vw_DriverStandingsBySeason
WHERE Season = 2020
ORDER BY TotalPoints DESC;

-- Test 3.4: vw_PitStopSummary
SELECT *
FROM vw_PitStopSummary

-- Test 3.5: vw_RaceDetails
SELECT *
FROM vw_RaceDetails

-- Test 3.6: vw_TeamPerformanceBySeason (sezon 2020)
SELECT *
FROM vw_TeamPerformanceBySeason
WHERE Season = 2020
ORDER BY TotalPoints DESC;

-- ============================================================
-- SECȚIUNEA 4: PROCEDURI STOCATE CRUD
-- Testare: Create, Read, Update, Delete
-- ============================================================

-- !!! NU UITA DE TRIGGERE

-- Test 4.1 CREATE:  Adăugare cursă completă Bahrain GP 2025
-- Pas 1: Insert cursă
EXEC sp_Race_Insert 
    @year = 2025, 
    @round = 4, 
    @circuitName = 'Bahrain International Circuit', 
    @name = 'Bahrain Grand Prix', 
    @date = '2025-03-30';

-- Pas 2: Insert calificări - TOȚI cei 20 piloți
-- Q3 (Top 10)
EXEC sp_Qualifying_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Oscar', @driverSurname='Piastri', @teamName='McLaren', @position=1, @q1='1:30.500', @q2='1:30.200', @q3='1:29.841';
EXEC sp_Qualifying_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='George', @driverSurname='Russell', @teamName='Mercedes', @position=2, @q1='1:30.600', @q2='1:30.300', @q3='1:30.009';
EXEC sp_Qualifying_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Charles', @driverSurname='Leclerc', @teamName='Ferrari', @position=3, @q1='1:30.700', @q2='1:30.400', @q3='1:30.175';
EXEC sp_Qualifying_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Andrea Kimi', @driverSurname='Antonelli', @teamName='Mercedes', @position=4, @q1='1:30.800', @q2='1:30.500', @q3='1:30.213';
EXEC sp_Qualifying_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Pierre', @driverSurname='Gasly', @teamName='Alpine F1 Team', @position=5, @q1='1:30.900', @q2='1:30.600', @q3='1:30.216';
EXEC sp_Qualifying_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Lando', @driverSurname='Norris', @teamName='McLaren', @position=6, @q1='1:31.000', @q2='1:30.700', @q3='1:30.267';
EXEC sp_Qualifying_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Max', @driverSurname='Verstappen', @teamName='Red Bull', @position=7, @q1='1:31.100', @q2='1:30.800', @q3='1:30.423';
EXEC sp_Qualifying_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Carlos', @driverSurname='Sainz', @teamName='Williams', @position=8, @q1='1:31.200', @q2='1:30.900', @q3='1:30.680';
EXEC sp_Qualifying_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Lewis', @driverSurname='Hamilton', @teamName='Ferrari', @position=9, @q1='1:31.300', @q2='1:31.000', @q3='1:30.772';
EXEC sp_Qualifying_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Yuki', @driverSurname='Tsunoda', @teamName='RB F1 Team', @position=10, @q1='1:31.400', @q2='1:31.100', @q3='1:31.303';

-- Q2 Eliminați (11-15)
EXEC sp_Qualifying_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Jack', @driverSurname='Doohan', @teamName='Alpine F1 Team', @position=11, @q1='1:31.500', @q2='1:31.200';
EXEC sp_Qualifying_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Isack', @driverSurname='Hadjar', @teamName='RB F1 Team', @position=12, @q1='1:31.600', @q2='1:31.300';
EXEC sp_Qualifying_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Fernando', @driverSurname='Alonso', @teamName='Aston Martin', @position=13, @q1='1:31.700', @q2='1:31.400';
EXEC sp_Qualifying_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Esteban', @driverSurname='Ocon', @teamName='Haas F1 Team', @position=14, @q1='1:31.800', @q2='1:31.500';
EXEC sp_Qualifying_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Alexander', @driverSurname='Albon', @teamName='Williams', @position=15, @q1='1:31.900', @q2='1:31.600';

-- Q1 Eliminați (16-20)
EXEC sp_Qualifying_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Nico', @driverSurname='Hülkenberg', @teamName='Sauber', @position=16, @q1='1:32.000';
EXEC sp_Qualifying_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Liam', @driverSurname='Lawson', @teamName='Red Bull', @position=17, @q1='1:32.100';
EXEC sp_Qualifying_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Gabriel', @driverSurname='Bortoleto', @teamName='Sauber', @position=18, @q1='1:32.200';
EXEC sp_Qualifying_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Lance', @driverSurname='Stroll', @teamName='Aston Martin', @position=19, @q1='1:32.300';
EXEC sp_Qualifying_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Oliver', @driverSurname='Bearman', @teamName='Haas F1 Team', @position=20, @q1='1:32.400';

-- Pas 3: Insert rezultate cursă - TOȚI cei 20 piloți
-- Top 10 (Puncte)
EXEC sp_RaceResult_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Oscar', @driverSurname='Piastri', @teamName='McLaren', @grid=1, @position='1', @positionOrder=1, @points=25, @laps=57, @time='1:35:39.435', @statusName='Finished';
EXEC sp_RaceResult_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='George', @driverSurname='Russell', @teamName='Mercedes', @grid=2, @position='2', @positionOrder=2, @points=18, @laps=57, @time='+15.499', @statusName='Finished';
EXEC sp_RaceResult_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Lando', @driverSurname='Norris', @teamName='McLaren', @grid=6, @position='3', @positionOrder=3, @points=15, @laps=57, @time='+16.273', @statusName='Finished';
EXEC sp_RaceResult_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Charles', @driverSurname='Leclerc', @teamName='Ferrari', @grid=3, @position='4', @positionOrder=4, @points=12, @laps=57, @time='+19.679', @statusName='Finished';
EXEC sp_RaceResult_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Lewis', @driverSurname='Hamilton', @teamName='Ferrari', @grid=9, @position='5', @positionOrder=5, @points=10, @laps=57, @time='+27.993', @statusName='Finished';
EXEC sp_RaceResult_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Max', @driverSurname='Verstappen', @teamName='Red Bull', @grid=7, @position='6', @positionOrder=6, @points=8, @laps=57, @time='+34.395', @statusName='Finished';
EXEC sp_RaceResult_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Pierre', @driverSurname='Gasly', @teamName='Alpine F1 Team', @grid=5, @position='7', @positionOrder=7, @points=6, @laps=57, @time='+36.002', @statusName='Finished';
EXEC sp_RaceResult_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Esteban', @driverSurname='Ocon', @teamName='Haas F1 Team', @grid=14, @position='8', @positionOrder=8, @points=4, @laps=57, @time='+44.244', @statusName='Finished';
EXEC sp_RaceResult_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Yuki', @driverSurname='Tsunoda', @teamName='RB F1 Team', @grid=10, @position='9', @positionOrder=9, @points=2, @laps=57, @time='+45.061', @statusName='Finished';
EXEC sp_RaceResult_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Oliver', @driverSurname='Bearman', @teamName='Haas F1 Team', @grid=20, @position='10', @positionOrder=10, @points=1, @laps=57, @time='+47.594', @statusName='Finished';

-- Restul clasamentului (11-18)
EXEC sp_RaceResult_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Andrea Kimi', @driverSurname='Antonelli', @teamName='Mercedes', @grid=4, @position='11', @positionOrder=11, @points=0, @laps=57, @time='+48.016', @statusName='Finished';
EXEC sp_RaceResult_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Alexander', @driverSurname='Albon', @teamName='Williams', @grid=15, @position='12', @positionOrder=12, @points=0, @laps=57, @time='+48.839', @statusName='Finished';
EXEC sp_RaceResult_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Isack', @driverSurname='Hadjar', @teamName='RB F1 Team', @grid=12, @position='13', @positionOrder=13, @points=0, @laps=57, @time='+56.314', @statusName='Finished';
EXEC sp_RaceResult_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Jack', @driverSurname='Doohan', @teamName='Alpine F1 Team', @grid=11, @position='14', @positionOrder=14, @points=0, @laps=57, @time='+57.806', @statusName='Finished';
EXEC sp_RaceResult_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Fernando', @driverSurname='Alonso', @teamName='Aston Martin', @grid=13, @position='15', @positionOrder=15, @points=0, @laps=57, @time='+1:00.340', @statusName='Finished';
EXEC sp_RaceResult_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Liam', @driverSurname='Lawson', @teamName='Red Bull', @grid=17, @position='16', @positionOrder=16, @points=0, @laps=57, @time='+1:04.435', @statusName='Finished';
EXEC sp_RaceResult_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Lance', @driverSurname='Stroll', @teamName='Aston Martin', @grid=19, @position='17', @positionOrder=17, @points=0, @laps=57, @time='+1:05.489', @statusName='Finished';
EXEC sp_RaceResult_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Gabriel', @driverSurname='Bortoleto', @teamName='Sauber', @grid=18, @position='18', @positionOrder=18, @points=0, @laps=57, @time='+1:06.872', @statusName='Finished';

-- DNF/DSQ (19-20)
EXEC sp_RaceResult_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Nico', @driverSurname='Hülkenberg', @teamName='Sauber', @grid=16, @position='DSQ', @positionOrder=19, @points=0, @laps=57, @statusName='Disqualified';
EXEC sp_RaceResult_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Carlos', @driverSurname='Sainz', @teamName='Williams', @grid=8, @position='R', @positionOrder=20, @points=0, @laps=0, @statusName='Mechanical';

-- Pas 4:  Insert pit stops - TOȚI piloții care au terminat cursa
-- Piastri (P1)
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Oscar', @driverSurname='Piastri', @stop=1, @lap=15, @duration='2.456', @milliseconds=2456;
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Oscar', @driverSurname='Piastri', @stop=2, @lap=35, @duration='2.389', @milliseconds=2389;

-- Russell (P2)
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='George', @driverSurname='Russell', @stop=1, @lap=16, @duration='2.567', @milliseconds=2567;
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='George', @driverSurname='Russell', @stop=2, @lap=36, @duration='2.478', @milliseconds=2478;

-- Norris (P3)
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Lando', @driverSurname='Norris', @stop=1, @lap=14, @duration='2.512', @milliseconds=2512;
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Lando', @driverSurname='Norris', @stop=2, @lap=34, @duration='2.445', @milliseconds=2445;

-- Leclerc (P4)
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Charles', @driverSurname='Leclerc', @stop=1, @lap=17, @duration='2.601', @milliseconds=2601;
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Charles', @driverSurname='Leclerc', @stop=2, @lap=37, @duration='2.534', @milliseconds=2534;

-- Hamilton (P5)
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Lewis', @driverSurname='Hamilton', @stop=1, @lap=16, @duration='2.623', @milliseconds=2623;
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Lewis', @driverSurname='Hamilton', @stop=2, @lap=36, @duration='2.556', @milliseconds=2556;

-- Verstappen (P6)
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Max', @driverSurname='Verstappen', @stop=1, @lap=15, @duration='2.589', @milliseconds=2589;
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Max', @driverSurname='Verstappen', @stop=2, @lap=35, @duration='2.501', @milliseconds=2501;

-- Gasly (P7)
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Pierre', @driverSurname='Gasly', @stop=1, @lap=16, @duration='2.634', @milliseconds=2634;
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Pierre', @driverSurname='Gasly', @stop=2, @lap=36, @duration='2.587', @milliseconds=2587;

-- Ocon (P8)
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Esteban', @driverSurname='Ocon', @stop=1, @lap=18, @duration='2.712', @milliseconds=2712;
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Esteban', @driverSurname='Ocon', @stop=2, @lap=38, @duration='2.645', @milliseconds=2645;

-- Tsunoda (P9)
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Yuki', @driverSurname='Tsunoda', @stop=1, @lap=17, @duration='2.678', @milliseconds=2678;
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Yuki', @driverSurname='Tsunoda', @stop=2, @lap=37, @duration='2.612', @milliseconds=2612;

-- Bearman (P10)
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Oliver', @driverSurname='Bearman', @stop=1, @lap=19, @duration='2.745', @milliseconds=2745;
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Oliver', @driverSurname='Bearman', @stop=2, @lap=39, @duration='2.689', @milliseconds=2689;

-- Antonelli (P11)
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Andrea Kimi', @driverSurname='Antonelli', @stop=1, @lap=16, @duration='2.698', @milliseconds=2698;
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Andrea Kimi', @driverSurname='Antonelli', @stop=2, @lap=36, @duration='2.634', @milliseconds=2634;

-- Albon (P12)
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Alexander', @driverSurname='Albon', @stop=1, @lap=17, @duration='2.723', @milliseconds=2723;
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Alexander', @driverSurname='Albon', @stop=2, @lap=37, @duration='2.667', @milliseconds=2667;

-- Hadjar (P13)
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Isack', @driverSurname='Hadjar', @stop=1, @lap=18, @duration='2.756', @milliseconds=2756;
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Isack', @driverSurname='Hadjar', @stop=2, @lap=38, @duration='2.701', @milliseconds=2701;

-- Doohan (P14)
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Jack', @driverSurname='Doohan', @stop=1, @lap=19, @duration='2.789', @milliseconds=2789;
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Jack', @driverSurname='Doohan', @stop=2, @lap=39, @duration='2.734', @milliseconds=2734;

-- Alonso (P15)
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Fernando', @driverSurname='Alonso', @stop=1, @lap=17, @duration='2.812', @milliseconds=2812;
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Fernando', @driverSurname='Alonso', @stop=2, @lap=37, @duration='2.756', @milliseconds=2756;

-- Lawson (P16)
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Liam', @driverSurname='Lawson', @stop=1, @lap=18, @duration='2.845', @milliseconds=2845;
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Liam', @driverSurname='Lawson', @stop=2, @lap=38, @duration='2.789', @milliseconds=2789;

-- Stroll (P17)
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Lance', @driverSurname='Stroll', @stop=1, @lap=19, @duration='2.878', @milliseconds=2878;
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Lance', @driverSurname='Stroll', @stop=2, @lap=39, @duration='2.823', @milliseconds=2823;

-- Bortoleto (P18)
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Gabriel', @driverSurname='Bortoleto', @stop=1, @lap=20, @duration='2.901', @milliseconds=2901;
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Gabriel', @driverSurname='Bortoleto', @stop=2, @lap=40, @duration='2.856', @milliseconds=2856;

-- Hülkenberg (DSQ - dar a făcut pitstops)
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Nico', @driverSurname='Hülkenberg', @stop=1, @lap=17, @duration='2.834', @milliseconds=2834;
EXEC sp_PitStop_Insert @raceName='Bahrain Grand Prix', @raceYear=2025, @driverForename='Nico', @driverSurname='Hülkenberg', @stop=2, @lap=37, @duration='2.778', @milliseconds=2778;

-- Sainz (DNF - nu a făcut pitstops, abandon mecanic înainte)

-- Test 4.2 READ:  Citire date
EXEC sp_Qualifying_GetByRace @raceName='Bahrain Grand Prix', @year=2025;
EXEC sp_RaceResult_GetByRace @raceName='Bahrain Grand Prix', @year=2025;

-- Test 4.3 UPDATE: Actualizare pilot
-- Pas 1: Verificare date înainte
SELECT forename, surname, code FROM Drivers WHERE forename='Oscar' AND surname='Piastri';

-- Pas 2: Update
EXEC sp_Driver_Update 
    @forename='Oscar', 
    @surname='Piastri', 
    @newDriverRef='piastri_test';

-- Pas 3: Verificare după update
SELECT forename, surname, code, driverRef FROM Drivers WHERE forename='Oscar' AND surname='Piastri';

-- Pas 4: Revenire la valoarea originală
EXEC sp_Driver_Update 
    @forename='Oscar', 
    @surname='Piastri', 
    @newDriverRef='piastri';

-- ============================================================
-- SECȚIUNEA 5: TRIGGERE DML
-- Testare:  Triggere pe INSERT/UPDATE/DELETE
-- ============================================================

-- Test 5.1: Trigger trg_RaceResults_UpdateDriverWins
SELECT forename, surname, totalWins 
FROM Drivers 
WHERE forename='Oscar' AND surname='Piastri';

-- Test 5.2: Trigger trg_Drivers_Audit
SELECT TOP 5
    Operation,
    RecordId,
    NewValues,
    changedAt
FROM AuditLog
WHERE TableName = 'Drivers'
ORDER BY changedAt DESC;

-- ============================================================
-- SECȚIUNEA 6: TRIGGERE DDL
-- Testare:  Trigger pentru modificări structură DB
-- ============================================================

-- Test 6.1: Verificare trigger DDL există
SELECT name, is_disabled 
FROM sys.triggers 
WHERE parent_class_desc = 'DATABASE';

-- Test 6.2: Test trigger DDL
-- Pas 1: Creare tabel test
CREATE TABLE TestDDLTrigger (
    id INT PRIMARY KEY,
    testCol VARCHAR(50)
);

-- Pas 2: Verificare în audit log
SELECT TOP 3
    EventType,
    ObjectName,
    ObjectType,
    ExecutedAt
FROM DDLAuditLog
ORDER BY ExecutedAt DESC;

-- Pas 3: Ștergere tabel test
DROP TABLE TestDDLTrigger;

-- ============================================================
-- SECȚIUNEA 7: CURSOARE
-- Testare: Proceduri cu cursoare
-- ============================================================

-- Test 7.1: Clasament sezon cu cursor
EXEC sp_GenerateSeasonStandingsReport @year = 2025;

-- Test 7.2: Diferențe puncte cu cursor
EXEC sp_CalculateChampionshipGaps @year = 2025;

-- Test 7.3: Clasament constructori cu cursor
EXEC sp_GenerateConstructorStandingsReport @year = 2025;

-- ============================================================
-- SECȚIUNEA 8: UTILIZATORI ȘI ROLURI
-- Testare:  Securitate și drepturi
-- ============================================================

-- Test 8.1: Roluri personalizate
SELECT name AS Rol, create_date
FROM sys.database_principals
WHERE type = 'R' AND name LIKE 'db_f1%';

-- Test 8.2: Utilizatori creați
SELECT name AS Utilizator, default_schema_name, create_date
FROM sys.database_principals
WHERE type = 'S' AND name LIKE 'f1_%';

-- Test 8.3: Mapare utilizatori-roluri
SELECT 
    USER_NAME(rm.member_principal_id) AS Utilizator,
    USER_NAME(rm.role_principal_id) AS Rol
FROM sys.database_role_members rm
WHERE USER_NAME(rm.role_principal_id) LIKE 'db_f1%';

-- ============================================================
-- SECȚIUNEA 9: JOBS TRANSACT-SQL
-- Testare: Proceduri pentru jobs de mentenanță
-- ============================================================

-- Test 9.1: Procedură cleanup audit log
EXEC sp_CleanupAuditLogs @daysToKeep = 7;

-- Test 9.2: Generare raport sezon
EXEC sp_GenerateSeasonSummaryReport @year = 2025;

-- Test 9.3: Listare backup-uri
EXEC sp_Backup_ListFiles;

-- ============================================================
-- SECȚIUNEA 10: BACKUP ȘI RESTORE
-- Testare: Strategii backup/restore
-- ============================================================

-- Test 10.1: Listare backup-uri existente
EXEC sp_Backup_ListFiles;

-- ============================================================
-- SECȚIUNEA 11: PROCEDURI AVANSATE
-- Testare: Funcționalități complexe
-- ============================================================

-- Test 11.1: Comparare piloți simplu
EXEC sp_CompareDriversAdvanced
    @driver1Forename = 'Lewis',
    @driver1Surname = 'Hamilton',
    @driver2Forename = 'Max',
    @driver2Surname = 'Verstappen',
    @year = 2020,
    @includeRaceDetails = 1;

-- Test 11.2: Comparare piloți avansat
EXEC sp_CompareDriversAdvanced 
    @driver1Forename = 'Nigel',
    @driver1Surname = 'Mansell',
    @driver2Forename = 'Ayrton',
    @driver2Surname = 'Senna',
    @year = 1992,
    @includeRaceDetails = 1;

-- Test 11.3: Predicție rezultat cursă
EXEC sp_Race_GetByYear @year = 2025;
EXEC sp_PredictRaceResult 
    @circuitName = 'Silverstone',
    @year = 2025;

-- Test 11.4: Analiză performanță pilot sezon
EXEC sp_AnalyzeDriverSeasonPerformance 
    @driverForename = 'Lewis',
    @driverSurname = 'Hamilton',
    @year = 2020;

-- Test 11.5: Analiză strategie optimă pit stop
EXEC sp_AnalyzeOptimalPitStrategy 
    @circuitName = 'Bahrain International Circuit',
    @topN = 10;

-- Test 11.6: Analiză fiabilitate echipă
EXEC sp_AnalyzeTeamReliability 
    @teamName = 'Ferrari',
    @year = 2024;

EXEC sp_AnalyzeTeamReliability 
    @teamName = 'Ferrari'

-- ============================================================
-- SECȚIUNEA 12:  ALTELE - PROCEDURI RĂMASE ȘI VEDERI
-- Testare:  Proceduri non-CRUD, vederi, rapoarte, analize
-- ============================================================

-- ============================================================
-- 12.1 CONTRACTE PILOȚI
-- ============================================================

-- Test: Vizualizare contracte pilot specific
EXEC sp_DriverContracts_GetByDriver 
    @driverForename = 'Fernando',
    @driverSurname = 'Alonso';

-- Test: Vizualizare piloți pentru o echipă
EXEC sp_DriverContracts_GetByTeam 
    @teamName = 'Ferrari';

-- ============================================================
-- 12.2 CURSE
-- ============================================================

EXEC sp_RaceResult_GetByRace
    @raceName = 'British Grand Prix',
    @year = 2024;
