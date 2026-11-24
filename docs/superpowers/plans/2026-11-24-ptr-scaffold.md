# PTR Project Scaffold Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the PTR (Project Traffic Reduce) multi-module Java/Spring + Docker + Python bridge repository skeleton that matches the approved design spec.

**Architecture:** Gradle multi-module monorepo under `com.ptr`. Java owns ETL, domain, grid, vehicle runtime, orchestrator, and metrics. Python `sumo-bridge` is a thin TraCI adapter. Postgres and Redis run via Docker Compose on the desktop.

**Tech Stack:** Java 17, Spring Boot 3.3.x, Spring Batch, Spring Data JPA, Gradle Kotlin DSL, PostgreSQL 16, Redis 7, Python 3.11+ (bridge later), SUMO (later).

## Global Constraints

- Project name: Project Traffic Reduce (PTR); package root `com.ptr`; Redis prefix `ptr:`
- Detectors in scope: D-35, D-38, D-34, D-37, B-17; sinks only B-11, B-16; exclude D-42
- Large TOPIS xlsx stay outside git (OneDrive path); fixtures only in-repo
- Desktop-local execution only for v1

---

### Task 1: Repository skeleton and Gradle multi-module build

**Files:**
- Create: `C:\Users\ryudw\source\ptr\.gitignore`
- Create: `C:\Users\ryudw\source\ptr\settings.gradle.kts`
- Create: `C:\Users\ryudw\source\ptr\build.gradle.kts`
- Create: `C:\Users\ryudw\source\ptr\gradle.properties`
- Create: module `build.gradle.kts` + package dirs for `ptr-domain`, `ptr-etl`, `ptr-grid`, `ptr-vehicle`, `ptr-orchestrator`, `ptr-metrics`
- Create: `ptr-orchestrator` Spring Boot entrypoint
- Create: `README.md`, `docker-compose.yml`
- Create: `sumo-bridge/README.md`, `sumo/.gitkeep`, `data/fixtures/.gitkeep`

**Interfaces:**
- Produces: Gradle modules compiling with `./gradlew :ptr-orchestrator:compileJava`
- Produces: `docker compose config` valid for services `postgres`, `redis`

- [ ] **Step 1: Add root Gradle files, modules, Docker, README**
- [ ] **Step 2: Generate Gradle wrapper and compile**
- [ ] **Step 3: Commit scaffold**

---

### Task 2 (next plan): Domain entities + ETL weekday filter

Deferred to a follow-up plan after scaffold compiles. Covers JPA entities from the design ERD and Spring Batch Excel ingest for 2025 TOPIS files.
