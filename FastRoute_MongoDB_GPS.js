// ============================================================
//  FastRoute Logistics Pvt. Ltd.
//  Working Prototype — MongoDB GPS_EVENT Collection
//  Database Systems MBA Project | Anuj, Bharat, Bhavesh
//  Run in: mongosh fastroute_gps
// ============================================================

// ── Database & Collection Setup ───────────────────────────────
use('fastroute_gps');

// Drop collection if re-running
db.gps_event.drop();

// Create Geospatial + VehicleID indexes for fast lookups
db.gps_event.createIndex({ vehicle_id: 1, timestamp: -1 });
db.gps_event.createIndex({ location: "2dsphere" });
db.gps_event.createIndex({ timestamp: -1 });

// ── Sample GPS Documents ──────────────────────────────────────
// Schema: schema-flexible JSON documents — no rigid table structure
// Each document = one GPS ping from a vehicle (every 30 seconds)

db.gps_event.insertMany([
  {
    vehicle_id:    1,
    plate_no:      "JH01AB1234",
    timestamp:     new Date(),
    location: {
      type:        "Point",
      coordinates: [85.3096, 23.3441]   // [longitude, latitude] — Ranchi
    },
    speed_kmph:    62.4,
    fuel_level_pct: 74.2,
    engine_status: "Running",
    alert_type:    null,
    zone_id:       "JH-EAST-01",
    driver_id:     1
  },
  {
    vehicle_id:    2,
    plate_no:      "BR03CD5678",
    timestamp:     new Date(Date.now() - 30000),
    location: {
      type:        "Point",
      coordinates: [85.1376, 25.5941]   // Patna
    },
    speed_kmph:    0,
    fuel_level_pct: 22.5,
    engine_status: "Idle",
    alert_type:    "LOW_FUEL",
    zone_id:       "BR-CENTRAL-02",
    driver_id:     2
  },
  {
    vehicle_id:    3,
    plate_no:      "MH02EF9012",
    timestamp:     new Date(Date.now() - 60000),
    location: {
      type:        "Point",
      coordinates: [72.8777, 19.0760]   // Mumbai
    },
    speed_kmph:    44.1,
    fuel_level_pct: 58.7,
    engine_status: "Running",
    alert_type:    null,
    zone_id:       "MH-WEST-01",
    driver_id:     3
  },
  {
    vehicle_id:    4,
    plate_no:      "KA05GH3456",
    timestamp:     new Date(Date.now() - 15000),
    location: {
      type:        "Point",
      coordinates: [77.5946, 12.9716]   // Bangalore
    },
    speed_kmph:    28.3,
    fuel_level_pct: 88.0,
    engine_status: "Running",
    alert_type:    null,
    zone_id:       "KA-SOUTH-01",
    driver_id:     4
  },
  {
    vehicle_id:    5,
    plate_no:      "UP07IJ7890",
    timestamp:     new Date(Date.now() - 90000),
    location: {
      type:        "Point",
      coordinates: [80.9462, 26.8467]   // Lucknow
    },
    speed_kmph:    0,
    fuel_level_pct: 45.0,
    engine_status: "Off",
    alert_type:    "ENGINE_OFF_UNEXPECTED",
    zone_id:       "UP-NORTH-03",
    driver_id:     5
  }
]);

// ══════════════════════════════════════════════════════════════
// OPERATIONAL QUERIES (Real-Time Dashboard)
// ══════════════════════════════════════════════════════════════

// Q1: Latest location for ALL active vehicles (live map feed)
db.gps_event.aggregate([
  { $sort: { vehicle_id: 1, timestamp: -1 } },
  { $group: {
      _id:            "$vehicle_id",
      plate_no:       { $first: "$plate_no" },
      last_seen:      { $first: "$timestamp" },
      coordinates:    { $first: "$location.coordinates" },
      speed_kmph:     { $first: "$speed_kmph" },
      fuel_level_pct: { $first: "$fuel_level_pct" },
      engine_status:  { $first: "$engine_status" },
      alert_type:     { $first: "$alert_type" }
  }},
  { $sort: { _id: 1 } }
]);

// Q2: All active alerts (LOW_FUEL, ENGINE_OFF, BREAKDOWN)
db.gps_event.aggregate([
  { $match:  { alert_type: { $ne: null } } },
  { $sort:   { vehicle_id: 1, timestamp: -1 } },
  { $group: {
      _id:         "$vehicle_id",
      plate_no:    { $first: "$plate_no" },
      alert_type:  { $first: "$alert_type" },
      last_seen:   { $first: "$timestamp" },
      coordinates: { $first: "$location.coordinates" }
  }}
]);

// Q3: Geospatial — find all vehicles within 50 km of Ranchi HQ
db.gps_event.find({
  location: {
    $near: {
      $geometry:    { type: "Point", coordinates: [85.3096, 23.3441] },
      $maxDistance: 50000   // 50 km in metres
    }
  }
}, { plate_no: 1, speed_kmph: 1, timestamp: 1, _id: 0 });

// Q4: Vehicles idle for > 30 minutes with engine running (fleet waste)
db.gps_event.find({
  speed_kmph:    0,
  engine_status: "Running",
  timestamp:     { $lte: new Date(Date.now() - 30 * 60 * 1000) }
}, { plate_no: 1, zone_id: 1, fuel_level_pct: 1, timestamp: 1, _id: 0 });
