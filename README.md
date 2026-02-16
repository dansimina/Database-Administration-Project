# 🏎️ Formula 1 Database

A comprehensive SQL Server database for managing and analyzing Formula 1 World Championship data — covering every season from **1950 to 2024**.

Built with **Microsoft SQL Server** and **Transact-SQL (T-SQL)**, this project provides a fully normalized relational database with stored procedures, views, triggers, audit logging, and advanced analytics.

---

## 📐 Database Schema

![Database Diagram](Diagrama.png)

---

## 📦 Features

- **Complete F1 historical data** — drivers, teams, circuits, races, results, qualifying, and pit stops from 1950–2024
- **Full CRUD operations** via stored procedures for all major entities
- **Advanced analytics** — championship standings, head-to-head comparisons, driver career stats, team reliability analysis
- **Race prediction engine** — weighted scoring algorithm using current form, historical circuit performance, and team performance
- **Automated statistics** — triggers that auto-update driver wins and pole positions on every result change
- **Complete audit system** — DML and DDL audit logging with automatic cleanup
- **Backup & restore** — automated full and differential backup strategy with monitoring
- **Role-based access control** — three-tier permission model (admin, analyst, data entry)

---

## 🗂️ Database Structure

### Geographic Reference Tables
| Table | Description |
|-------|-------------|
| `Continents` | Continent names and codes |
| `Countries` | Countries with ISO codes and continent reference |
| `Cities` | Cities with country reference |
| `Nationalities` | Driver and team nationalities |

### Core Formula 1 Tables
| Table | Description |
|-------|-------------|
| `Drivers` | Driver profiles: name, code, nationality, career stats |
| `Teams` | Constructors: name, nationality, reference |
| `Circuits` | Race circuits: name, city, country |
| `Seasons` | F1 seasons with status (ONGOING / FINISHED) |
| `Races` | Individual races: season, round, circuit, date |
| `RaceResults` | Race results: position, points, lap times, fastest lap |
| `QualifyingResults` | Qualifying results: Q1/Q2/Q3 times, grid position |
| `PitStops` | Pit stop data: lap, duration (ms) |
| `DriverContracts` | Driver–team contracts per season |
| `RaceStatus` | Possible race statuses (Finished, DNF, Accident, etc.) |

### Audit & Reporting Tables
| Table | Description |
|-------|-------------|
| `AuditLog` | DML change log (INSERT / UPDATE / DELETE) |
| `DDLAuditLog` | DDL change log (CREATE / ALTER / DROP) |
| `SeasonReports` | Auto-generated season summary reports |

---

## 🔧 Stored Procedures

### CRUD Operations
Full CRUD procedures are available for all major entities:
- `sp_Driver_*` — GetAll, GetByName, Insert, Update, Delete
- `sp_Team_*` — GetAll, GetByName, Insert, Update, Delete
- `sp_Circuit_*`, `sp_Race_*`, `sp_RaceResult_*`, `sp_Qualifying_*`, `sp_PitStop_*`, `sp_DriverContracts_*`

### Analytics & Reporting
| Procedure | Description |
|-----------|-------------|
| `sp_CompareDrivers` | Head-to-head driver comparison for a season |
| `sp_CompareDriversAdvanced` | Detailed comparison with qualifying battles, fastest laps, round-by-round |
| `sp_AnalyzeDriverSeasonPerformance` | Full driver season performance analysis with cumulative points |
| `sp_AnalyzeOptimalPitStrategy` | Optimal pit stop strategy analysis for a circuit |
| `sp_AnalyzeTeamReliability` | Team reliability: finishes vs. retirements |
| `sp_CalculateChampionshipGaps` | Championship gap after every race of a season |
| `sp_GenerateSeasonStandingsReport` | Final season driver standings with status labels |
| `sp_GenerateConstructorStandingsReport` | Constructor standings with detailed statistics |
| `sp_GenerateSeasonSummaryReport` | Season summary report saved to `SeasonReports` |
| `sp_PredictRaceResult` | Weighted race result prediction (form + history + team) |

### Utility & Maintenance
| Procedure | Description |
|-----------|-------------|
| `sp_RecalculateDriverStats` | Manually recalculate all driver wins and pole positions |
| `sp_DriverContracts_PopulateFromHistory` | Auto-populate driver contracts from race history |
| `sp_CleanupAuditLogs` | Delete audit log entries older than N days |
| `sp_Backup_Full` / `sp_Backup_Differential` | Perform full or differential database backup |
| `sp_Backup_ListFiles` | List the last 20 backups with metadata |
| `sp_Restore_Database` | Restore from full or full + differential backup |

---

## 👁️ Views

| View | Description |
|------|-------------|
| `vw_DriverCareerStats` | Complete career statistics per driver |
| `vw_DriverStandingsBySeason` | Driver standings by season with points, wins, podiums |
| `vw_TeamPerformanceBySeason` | Team performance per season |
| `vw_CircuitStatistics` | Circuit stats: total races, years active, avg pit stops |
| `vw_RaceDetails` | Full race details with circuit, city, country, continent |
| `vw_PitStopSummary` | Pit stop summary per race and driver |

---

## ⚙️ Triggers

| Trigger | Description |
|---------|-------------|
| `trg_Drivers_Audit` | Audits all INSERT / UPDATE / DELETE on the `Drivers` table |
| `trg_RaceResults_UpdateDriverWins` | Auto-updates `totalWins` when results change |
| `trg_QualifyingResults_UpdateDriverPoles` | Auto-updates `totalPolePositions` when qualifying changes |
| `trg_RaceResults_ValidatePoints` | Validates that points match the official F1 scoring system |
| `trg_DDL_DatabaseAudit` | Database-level DDL audit for all schema changes |

---

## 🔮 Race Prediction Algorithm

`sp_PredictRaceResult` uses a cursor-based weighted scoring model:

| Factor | Weight |
|--------|--------|
| Current season form | 40% |
| Historical performance on the specific circuit | 40% |
| Team performance | 20% |

Results include a **confidence level** (HIGH / MEDIUM / LOW) based on data availability.

---

## 🔐 Users & Roles

| Role | User | Permissions |
|------|------|-------------|
| `db_f1_admin` | `f1_admin_user` | Full CONTROL over the database |
| `db_f1_analyst` | `f1_analyst_user` | SELECT on all tables/views + EXECUTE on all analytics procedures |
| `db_f1_dataentry` | `f1_dataentry_user` | EXECUTE on CRUD procedures only — no direct table access |

The design follows the **principle of least privilege** — each role has only the permissions required for its function.

---

## 💾 Backup Strategy

| Backup Type | Frequency | Procedure |
|-------------|-----------|-----------|
| Full Backup | Every 60 minutes | `sp_Backup_Full` |
| Differential Backup | Every 15 minutes | `sp_Backup_Differential` |
| Audit Cleanup | Every 30 minutes | `sp_CleanupAuditLogs` (7-day retention) |
| Season Report | Every 15 minutes | `sp_GenerateSeasonSummaryReport` |

- **Recovery Point Objective (RPO):** max 15 minutes of data loss
- File format: `Formula1_FULL_YYYYMMDD_HHMMSS.bak` / `Formula1_DIFF_YYYYMMDD_HHMMSS.bak`

### Restore Examples

```sql
-- Restore from full backup only
EXEC sp_Restore_Database
    @fullBackupFile = 'D:\backup\Formula1_FULL_20251231.bak'

-- Restore full + differential
EXEC sp_Restore_Database
    @fullBackupFile = 'D:\backup\Formula1_FULL_20251231.bak',
    @diffBackupFile = 'D:\backup\Formula1_DIFF_20251231.bak'

-- Restore to a new database (for testing)
EXEC sp_Restore_Database
    @fullBackupFile = 'D:\backup\Formula1_FULL_20251231.bak',
    @newDatabaseName = 'Formula1_Test'
```

---

## 📊 Example Queries

```sql
-- Get full career stats for all drivers
SELECT * FROM vw_DriverCareerStats ORDER BY totalPoints DESC;

-- Compare two drivers in a season
EXEC sp_CompareDriversAdvanced
    @driver1Id = 1,
    @driver2Id = 2,
    @seasonYear = 2023;

-- Predict the result for an upcoming race
EXEC sp_PredictRaceResult
    @raceId = 1050;

-- Get championship standings gaps after each race
EXEC sp_CalculateChampionshipGaps
    @seasonYear = 2024;
```

---

## 🛠️ Tech Stack

- **DBMS:** Microsoft SQL Server
- **Language:** Transact-SQL (T-SQL)
- **Tools:** SQL Server Management Studio (SSMS)

---
