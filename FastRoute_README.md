# FastRoute Logistics — Database Systems Project
## Working Prototype Package | MBA – Operations & Management

**Team: Anuj, Bharat, Bhavesh**

---

## Files in This Package

| File | Description |
|------|-------------|
| `FastRoute_CaseStudy_OnePager.docx` | One-page Word document — business problem, entities, solution |
| `FastRoute_ERD.svg` | Entity Relationship Diagram (open in any browser or drawing tool) |
| `FastRoute_SQL_Schema.sql` | PostgreSQL schema — all 5 entities, sample data, 3 analytics queries |
| `FastRoute_MongoDB_GPS.js` | MongoDB GPS_EVENT collection — setup, sample data, 4 real-time queries |

---

## How to Run the Prototype

### PostgreSQL (SQL Schema + Sample Data)

**Prerequisites:** PostgreSQL 14+ installed

```bash
# Create database
psql -U postgres -c "CREATE DATABASE fastroute;"

# Run schema + seed data
psql -U postgres -d fastroute -f FastRoute_SQL_Schema.sql
```

Then test the analytics queries from the bottom of the file in psql or any SQL client (DBeaver, pgAdmin, TablePlus).

---

### MongoDB (GPS Real-Time Collection)

**Prerequisites:** MongoDB 6.0+ and mongosh installed

```bash
mongosh < FastRoute_MongoDB_GPS.js
```

Or paste into MongoDB Compass Shell / Atlas Data Explorer.

---

## Architecture Summary

```
SAP B1 / WMS (OLTP)          Power BI Dashboard
       │                             │
       ▼                             │ DirectQuery
  MS SQL Server ──────── PostgreSQL Read-Replica ──┘
  (Live Transactions)    (Analytics OLAP — isolated)

  GPS Devices ──► Streaming ──► MongoDB (GPS_EVENT)
                                     │
                              REST API ──► Client Web Portal
```

---

## Entity Summary

| Entity | PK | Key FKs | Role |
|--------|----|---------|------|
| CLIENT | ClientID | — | Stores client accounts and SLA contracts |
| SHIPMENT | ShipmentID | ClientID, VehicleID | Central fact table — links clients to vehicles |
| VEHICLE | VehicleID | DriverID | Fleet registry |
| DRIVER | DriverID | — | Driver profiles and zone assignments |
| ROUTE | RouteID | ShipmentID | Journey origin, destination, distance |
| GPS_EVENT | _id (MongoDB) | vehicle_id (ref) | Real-time IoT telemetry — NOT in SQL |

---

## Normalization Applied (3NF)

- **1NF:** Lat/Long stored as separate float fields (not a combined string)
- **2NF:** Client name lives in CLIENT table — never repeated in SHIPMENT
- **3NF:** Vehicle capacity in VEHICLE — no transitive dependency through shipment
