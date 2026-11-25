-- P1 demand schema (Flyway V1)
-- hour set: warmup 6/16 + peak 7-9 / 17-19

CREATE TABLE detector (
    id         BIGSERIAL PRIMARY KEY,
    code       VARCHAR(16)  NOT NULL,
    name       VARCHAR(100) NOT NULL,
    road_role  VARCHAR(16)  NOT NULL,
    lat        DOUBLE PRECISION NOT NULL,
    lon        DOUBLE PRECISION NOT NULL,
    CONSTRAINT uq_detector_code UNIQUE (code),
    CONSTRAINT ck_detector_road_role
        CHECK (road_role IN ('MAIN', 'PARALLEL', 'EXIT_SINK'))
);

CREATE TABLE detector_direction (
    id           BIGSERIAL PRIMARY KEY,
    detector_id  BIGINT NOT NULL REFERENCES detector (id),
    dir          VARCHAR(8) NOT NULL,
    label        VARCHAR(255) NOT NULL,
    CONSTRAINT uq_detector_direction UNIQUE (detector_id, dir),
    CONSTRAINT ck_detector_direction_dir CHECK (dir IN ('IN', 'OUT'))
);

CREATE TABLE holiday (
    holiday_date DATE PRIMARY KEY,
    holiday_name VARCHAR(100) NOT NULL
);

CREATE TABLE traffic_raw_hourly (
    id                     BIGSERIAL PRIMARY KEY,
    detector_direction_id  BIGINT NOT NULL REFERENCES detector_direction (id),
    obs_date               DATE NOT NULL,
    hour                   SMALLINT NOT NULL,
    volume                 INTEGER,
    day_of_week            VARCHAR(8),
    source_file            VARCHAR(255),
    CONSTRAINT uq_traffic_raw_hourly UNIQUE (detector_direction_id, obs_date, hour),
    CONSTRAINT ck_traffic_raw_hour CHECK (hour IN (6, 7, 8, 9, 16, 17, 18, 19))
);

CREATE TABLE traffic_hourly (
    id                     BIGSERIAL PRIMARY KEY,
    detector_direction_id  BIGINT NOT NULL REFERENCES detector_direction (id),
    obs_date               DATE NOT NULL,
    hour                   SMALLINT NOT NULL,
    volume                 INTEGER,
    CONSTRAINT uq_traffic_hourly UNIQUE (detector_direction_id, obs_date, hour),
    CONSTRAINT ck_traffic_hourly_hour CHECK (hour IN (6, 7, 8, 9, 16, 17, 18, 19))
);

CREATE TABLE demand_profile (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(64) NOT NULL,
    year        SMALLINT NOT NULL,
    peak        VARCHAR(8) NOT NULL,
    stat        VARCHAR(8) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_demand_profile UNIQUE (year, peak, stat),
    CONSTRAINT ck_demand_profile_peak CHECK (peak IN ('AM', 'PM')),
    CONSTRAINT ck_demand_profile_stat CHECK (stat IN ('MEDIAN', 'P90'))
);

CREATE TABLE demand_profile_slot (
    id                     BIGSERIAL PRIMARY KEY,
    profile_id             BIGINT NOT NULL REFERENCES demand_profile (id),
    detector_direction_id  BIGINT NOT NULL REFERENCES detector_direction (id),
    hour                   SMALLINT NOT NULL,
    vehs_per_hour          INTEGER NOT NULL,
    sample_n               INTEGER NOT NULL,
    CONSTRAINT uq_demand_profile_slot UNIQUE (profile_id, detector_direction_id, hour),
    CONSTRAINT ck_demand_profile_slot_hour CHECK (hour IN (6, 7, 8, 9, 16, 17, 18, 19))
);
