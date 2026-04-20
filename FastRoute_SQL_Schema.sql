-- ============================================================
--  FastRoute Logistics Pvt. Ltd.
--  Working Prototype — PostgreSQL Schema (Read-Replica / OLAP)
--  Database Systems MBA Project | Anuj, Bharat, Bhavesh
--  Normalized to 3NF | All 5 Core Entities
-- ============================================================

-- ── 1. CLIENT ──────────────────────────────────────────────
CREATE TABLE client (
    client_id   SERIAL        PRIMARY KEY,
    name        VARCHAR(150)  NOT NULL,
    contact     VARCHAR(100),
    sla_type    VARCHAR(30)   NOT NULL CHECK (sla_type IN ('Standard', 'Priority', 'SameDay')),
    state       VARCHAR(50)   NOT NULL,
    created_at  TIMESTAMP     DEFAULT NOW()
);

-- ── 2. DRIVER ──────────────────────────────────────────────
CREATE TABLE driver (
    driver_id   SERIAL        PRIMARY KEY,
    name        VARCHAR(150)  NOT NULL,
    license_no  VARCHAR(30)   UNIQUE NOT NULL,
    phone_no    VARCHAR(15),
    zone        VARCHAR(50)   NOT NULL
);

-- ── 3. VEHICLE ─────────────────────────────────────────────
CREATE TABLE vehicle (
    vehicle_id  SERIAL        PRIMARY KEY,
    driver_id   INT           REFERENCES driver(driver_id) ON DELETE SET NULL,
    plate_no    VARCHAR(20)   UNIQUE NOT NULL,
    capacity    INT           NOT NULL CHECK (capacity > 0),
    type        VARCHAR(30)   CHECK (type IN ('Truck', 'Van', 'Two-Wheeler'))
);

-- ── 4. SHIPMENT ────────────────────────────────────────────
CREATE TABLE shipment (
    shipment_id   SERIAL       PRIMARY KEY,
    client_id     INT          NOT NULL REFERENCES client(client_id) ON DELETE RESTRICT,
    vehicle_id    INT          REFERENCES vehicle(vehicle_id) ON DELETE SET NULL,
    status        VARCHAR(30)  NOT NULL DEFAULT 'Pending'
                               CHECK (status IN ('Pending','In-Transit','Delivered','Delayed','Cancelled')),
    created_at    TIMESTAMP    DEFAULT NOW(),
    sla_deadline  TIMESTAMP
);

-- ── 5. ROUTE ───────────────────────────────────────────────
CREATE TABLE route (
    route_id     SERIAL        PRIMARY KEY,
    shipment_id  INT           NOT NULL UNIQUE REFERENCES shipment(shipment_id) ON DELETE CASCADE,
    origin       VARCHAR(150)  NOT NULL,
    destination  VARCHAR(150)  NOT NULL,
    distance     DECIMAL(8,2)  NOT NULL CHECK (distance > 0)
);

-- ══════════════════════════════════════════════════════════════
-- SAMPLE DATA
-- ══════════════════════════════════════════════════════════════

INSERT INTO client (name, contact, sla_type, state) VALUES
  ('Hindustan Unilever Ltd.', 'procurement@hul.com',   'Priority',  'Maharashtra'),
  ('Apollo Pharma Dist.',     'ops@apollopharma.com',  'SameDay',   'Karnataka'),
  ('Flipkart Logistics',      'fc-ops@flipkart.com',   'Standard',  'Delhi'),
  ('Dabur India Ltd.',        'supply@dabur.com',      'Priority',  'Uttar Pradesh'),
  ('Cipla Ltd.',              'cold-chain@cipla.com',  'SameDay',   'Gujarat');

INSERT INTO driver (name, license_no, phone_no, zone) VALUES
  ('Ramesh Kumar',   'JH-01-2019-0001', '9801234567', 'Jharkhand'),
  ('Suresh Yadav',   'BR-03-2020-0042', '9712345678', 'Bihar'),
  ('Priya Sharma',   'MH-02-2018-0199', '9823456789', 'Maharashtra'),
  ('Arjun Patil',    'KA-05-2021-0087', '9934567890', 'Karnataka'),
  ('Meena Devi',     'UP-07-2017-0563', '9645678901', 'Uttar Pradesh');

INSERT INTO vehicle (driver_id, plate_no, capacity, type) VALUES
  (1, 'JH01AB1234', 5000,  'Truck'),
  (2, 'BR03CD5678', 2000,  'Van'),
  (3, 'MH02EF9012', 8000,  'Truck'),
  (4, 'KA05GH3456', 500,   'Two-Wheeler'),
  (5, 'UP07IJ7890', 3000,  'Van');

INSERT INTO shipment (client_id, vehicle_id, status, created_at, sla_deadline) VALUES
  (1, 1, 'In-Transit',  NOW() - INTERVAL '3 hours',  NOW() + INTERVAL '2 hours'),
  (2, 4, 'In-Transit',  NOW() - INTERVAL '1 hour',   NOW() + INTERVAL '30 minutes'),
  (3, 2, 'Delivered',   NOW() - INTERVAL '5 hours',  NOW() - INTERVAL '1 hour'),
  (4, 3, 'Delayed',     NOW() - INTERVAL '6 hours',  NOW() - INTERVAL '2 hours'),
  (5, 5, 'Pending',     NOW(),                        NOW() + INTERVAL '4 hours'),
  (1, 2, 'In-Transit',  NOW() - INTERVAL '2 hours',  NOW() + INTERVAL '3 hours'),
  (3, 1, 'In-Transit',  NOW() - INTERVAL '4 hours',  NOW() + INTERVAL '1 hour');

INSERT INTO route (shipment_id, origin, destination, distance) VALUES
  (1, 'Ranchi Warehouse',   'Mumbai Hub',       1320.5),
  (2, 'Bangalore DC',       'Chennai Port',      347.2),
  (3, 'Delhi NCR Hub',      'Gurgaon Client',     28.4),
  (4, 'Kanpur Depot',       'Lucknow Client',     84.1),
  (5, 'Ahmedabad DC',       'Surat Customer',    265.0),
  (6, 'Ranchi Warehouse',   'Kolkata Hub',       415.3),
  (7, 'Delhi NCR Hub',      'Noida Client',       22.7);

-- ══════════════════════════════════════════════════════════════
-- BUSINESS QUERIES (Power BI / Analytics)
-- ══════════════════════════════════════════════════════════════

-- Q1: Active shipments with SLA risk (for Power BI dashboard)
SELECT
    s.shipment_id,
    c.name            AS client,
    c.sla_type,
    v.plate_no        AS vehicle,
    d.name            AS driver,
    d.zone,
    s.status,
    r.origin,
    r.destination,
    r.distance        AS distance_km,
    s.sla_deadline,
    CASE
        WHEN s.sla_deadline < NOW() AND s.status NOT IN ('Delivered','Cancelled')
            THEN 'SLA BREACHED'
        WHEN s.sla_deadline < NOW() + INTERVAL '1 hour' AND s.status NOT IN ('Delivered','Cancelled')
            THEN 'AT RISK'
        ELSE 'ON TRACK'
    END               AS sla_status
FROM shipment s
JOIN client   c ON c.client_id  = s.client_id
JOIN vehicle  v ON v.vehicle_id = s.vehicle_id
JOIN driver   d ON d.driver_id  = v.driver_id
JOIN route    r ON r.shipment_id = s.shipment_id
WHERE s.status NOT IN ('Delivered', 'Cancelled')
ORDER BY s.sla_deadline ASC;

-- Q2: SLA miss summary by client (for management reporting)
SELECT
    c.name            AS client,
    c.sla_type,
    COUNT(*)          AS total_shipments,
    SUM(CASE WHEN s.sla_deadline < NOW() AND s.status != 'Delivered' THEN 1 ELSE 0 END) AS missed_sla,
    ROUND(
        100.0 * SUM(CASE WHEN s.sla_deadline < NOW() AND s.status != 'Delivered' THEN 1 ELSE 0 END)
             / COUNT(*), 1
    )                 AS sla_miss_pct
FROM shipment s
JOIN client c ON c.client_id = s.client_id
GROUP BY c.name, c.sla_type
ORDER BY sla_miss_pct DESC;

-- Q3: Fleet utilisation by zone
SELECT
    d.zone,
    COUNT(v.vehicle_id) AS total_vehicles,
    COUNT(s.shipment_id) FILTER (WHERE s.status = 'In-Transit') AS active_shipments,
    ROUND(
        100.0 * COUNT(s.shipment_id) FILTER (WHERE s.status = 'In-Transit')
             / COUNT(v.vehicle_id), 1
    ) AS utilisation_pct
FROM vehicle v
JOIN driver d ON d.driver_id = v.driver_id
LEFT JOIN shipment s ON s.vehicle_id = v.vehicle_id
GROUP BY d.zone
ORDER BY utilisation_pct DESC;
