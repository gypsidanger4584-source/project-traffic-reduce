# PTR (Project Traffic Reduce) — 설계 스펙

날짜: 2026-11-24  
상태: 초안 (구현 전 사용자 검토용)  
프로젝트명: **Project Traffic Reduce (PTR)**  
부제: 강남~양재 V2V 협조 주행 시뮬레이션

## 1. 목표

퇴근시간대 강남권 도로망에서 차량을 논리 인스턴스로 두고, 목적지·차선변경 의도를 교환하며 셀(그리드) 진입을 통제하는 협조 주행으로 **교통 정체를 줄이는(Traffic Reduce)** 효과를 시뮬한다. 협조 on/off(BASELINE vs COOP)를 비교해 평균 통행시간·정차·대기열을 측정한다.

포트폴리오 포지션: **Java 백엔드** (대규모 인스턴스 오케스트레이션, Redis 메시징, 락, 배치 파이프라인, ERD). SUMO는 도로 물리 엔진이며 Python은 TraCI 어댑터만 담당한다.

실행 환경: **개발자 데스크탑 로컬** (Docker로 Postgres·Redis, 로컬 SUMO).

## 2. 범위

### 2.1 도로·검지 지점

| 역할 | 지점 | 도로 |
|------|------|------|
| 주축 | D-35 | 강남대로 (강남역~뱅뱅사거리) |
| 동측 병렬 | D-38 | 언주로 (매봉터널) |
| 서측 병렬 | D-37 | 반포대로 (서초역) |
| 남측 횡축 | D-34 | 남부순환로 (예술의전당) |
| 서측 남측 연장 | B-17 | 반포대로 (우면산터널) |
| 출구 싱크만 | B-11, B-16 | 양재IC 경부·양재대로 — **네트워크 본선 수요로 쓰지 않음** |

제외: D-42(테헤란로), D-43(신사역), D-36(사평대로, 2024 무효 데이터).

공간 박스(대략): 북쪽 강남역, 남쪽 양재IC·예술의전당, 서쪽 반포대로, 동쪽 언주로 (남북 ~4–5km × 동서 ~3.5–4km). 그리드 셀 크기 목표 200–500m.

### 2.2 시간·수요

- 원천: `C:\Users\ryudw\OneDrive\바탕 화면\project etc\25년도 교통량\` 2025년 1–12월 월별 xlsx
- 주중 정의(2024 서울시 교통량 조사자료와 동일): **월–금, 공휴일 제외**
- 첨두 창: 출근 **07–09**, 퇴근 **17–19** (도시 전체·간선 유출 기준). 시뮬 우선 시나리오는 **퇴근 남하**
- 시뮬 워밍업: 16시부터 투입, 비교 구간은 17–19시
- 통계: 지점·방향·시간대별 **중앙값** 및 **P90** 프로파일 두 종
- B-11·B-16: 싱크·검증용 집계만. 경부 본선 통과 교통을 vehsPerHour로 넣지 않음
- 뱅뱅 이남 직진 비율 등 회전 분담은 검지기 부재로 **가정값을 문서에 고정**하고 민감도만 수행

### 2.3 비범위 (v1)

- 실제 신호 현시 이력 전수 재현 (고정 주기 근사 + 상대 비교)
- 2026년 11–12월 데이터
- 클라우드 배포, 멀티 테넌트, 인증/인가
- 차로별 TOPIS, 날씨·사고 이벤트

## 3. 아키텍처

스택: **Java(Spring) 메인 + Python TraCI 브리지 + SUMO + PostgreSQL + Redis**.

```
TOPIS xlsx → Spring Batch ETL → PostgreSQL
                ↓
         demand_profile
                ↓
     Sim Orchestrator (Spring)
        ↕ Redis Streams / locks
   Grid Controller · Vehicle Workers
                ↓
     Python sumo-bridge (TraCI)
                ↓
              SUMO
                ↓
         run_metric / cell_snapshot
```

| 모듈 | 기술 | 책임 |
|------|------|------|
| `etl` | Spring Batch | 엑셀 적재·평일 필터·프로파일·SUMO flow export |
| `domain` | JPA | 엔티티·리포지토리 (ERD) |
| `grid-controller` | Spring + Redis lock | 셀 슬롯 예약·진입 허가/거부 |
| `vehicle-runtime` | Spring workers | 논리 차량 상태, 의도 pub/sub |
| `sim-orchestrator` | Spring Boot | 런 생명주기, 틱 동기화, baseline/coop |
| `sumo-bridge` | Python | TraCI I/O만 |
| `metrics` | Spring | 통행시간·정차·대기열 집계 |
| `sumo/` | 데이터 | net.xml, routes, flows (생성물) |

멀티모듈 Gradle 모노레포. Python은 `sumo-bridge/` 서브디렉터리.

## 4. ERD (v1 기본)

원본/정제 분리, 프로파일 불변(새 버전 insert), 핫패스는 Redis.

### 4.1 마스터·수요

- `detector` — code, name, lat, lon, road_role(`MAIN`|`PARALLEL`|`EXIT_SINK`), lanes_in/out
- `detector_direction` — detector_id, dir(`IN`|`OUT`), labels, corridor_sense
- `holiday` — date, name (2025)
- `traffic_raw_hourly` — 엑셀 그대로
- `traffic_hourly` — 월–금 ∧ ¬holiday
- `demand_profile` — name, year, peak(AM/PM), stat(MEDIAN/P90)
- `demand_profile_slot` — profile_id, detector_id, dir, hour, vehs_per_hour

### 4.2 시뮬·그리드·차량

- `sim_run` — mode(`BASELINE`|`COOP`), profile_id, status, sumo_net_version, timestamps
- `grid_cell` — run_id, cell_key, bbox, max_vehicles, road_ids
- `vehicle_trip` — run_id, veh_id, origin/dest, depart/arrive, coop_enabled
- `slot_reservation` — veh_id, cell_key, state(`REQUESTED`|`GRANTED`|`DENIED`|`RELEASED`)
- `vehicle_intent_event` — 의도 이벤트(필요 시 샘플 flush; 주 경로는 Redis)
- `cell_snapshot` — sim_time, cell_key, count, avg_speed, density (샘플 간격)
- `run_metric` — metric key, value

## 5. 파이프라인

### 5.1 데이터 (Spring Batch)

1. ExtractExcel — 대상 지점·0–23시·방향  
2. WriteRaw → `traffic_raw_hourly`  
3. FilterWeekday → `traffic_hourly`  
4. BuildProfile → MEDIAN/P90 `demand_profile` + slots  
5. ExportFlows → SUMO `flows.xml` 조각  

### 5.2 런타임 틱

1. `sim_run` 생성  
2. 프로파일로 출발 스케줄  
3. 매 틱: Bridge←상태 → Redis → Grid 슬롯 → (COOP) 의도 교환 → Bridge→제어  
4. 종료 후 `run_metric`  

### 5.3 Redis

- `sim:{runId}:vehicle.state`
- `sim:{runId}:intent`
- `sim:{runId}:slot.request` / `slot.decision`
- `lock:cell:{runId}:{cellKey}`

### 5.4 데스크탑 기동 순서

1. `docker compose up -d` (Postgres, Redis)  
2. Batch ETL  
3. OSM → netconvert (네트워크)  
4. Orchestrator + Bridge  
5. BASELINE / COOP 두 런 비교  

## 6. 에러 처리

| 구간 | 실패 | 처리 |
|------|------|------|
| ETL 파싱 | 시트/컬럼 불일치 | 잡 실패 + 파일·시트명 로그. 부분 커밋 없음(스텝 단위 트랜잭션) |
| ETL 결측 | 지점·월 `-` | raw에는 null 허용, profile 집계 시 해당 일 제외. 유효 n 기록 |
| Bridge 단절 | TraCI/SUMO 죽음 | Orchestrator가 run `FAILED`, 부분 metric 저장 안 함(또는 `PARTIAL` 플래그 명시) |
| Redis 락 타임아웃 | 셀 경합 | 진입 DENIED → 감속/대기. 데드락 방지: 락 TTL + 재시도 상한 |
| 슬롯 초과 요청 | max_vehicles | DENIED, baseline과 동일 물리 제약 하에 coop만 의도 공유 |
| 수요 과다 | SUMO 삽입 실패 | 삽입 실패 카운트 metric화, run은 계속(또는 임계 시 FAILED) |

재실행: Batch는 idempotent(동일 source_file 재적재 시 raw 교체 정책 명시). Sim run은 새 row (불변 이력).

## 7. 테스트 경계

| 계층 | 내용 |
|------|------|
| 단위 | 평일/공휴일 필터, 중앙값·P90, 셀 슬롯 허가 상태머신 |
| 통합 | Batch: 샘플 xlsx fixture → DB 프로파일. Redis: request→decision 라운드트립 |
| 계약 | Orchestrator↔Bridge JSON 스키마 (상태/명령) |
| 시뮬 스모크 | 소규모 net + 소수 차량, GUI 없이 1분 틱 |
| 비교 검증 | 동일 seed·프로파일로 BASELINE vs COOP metric 차이 존재 여부(효과 크기 단정 금지) |

속도 검증(후속): TOPIS 1시간 구간 통행속도로 travel time 캘리브레이션 — v1 필수 아님, README에 후속으로 명시.

## 8. 신호·네트워크 (v1 근사)

- OSM + netconvert로 대상 박스 네트워크 생성  
- 표준링크·버스전용차로는 후속 보정  
- 주요 교차로만 **문서화된 고정 주기**; 전 구간 실현시 없음 → 정차·대기열은 **상대 비교**만 주장  
- C-ITS 실시간 API는 2025 이력 대체 불가. 선택적으로 현재 주기 참고용만  

## 9. 성공 기준 (v1)

1. 2025 평일 대상 지점 ETL → MEDIAN/P90 프로파일 DB 적재  
2. 합의 범위 SUMO net + flow로 baseline 런 완료  
3. Redis 경유 셀 슬롯 + (COOP) 의도 메시지 동작  
4. BASELINE vs COOP `run_metric` 비교 테이블/리포트  
5. README에 아키텍처·ERD·파이프라인·로컬 실행·성능(동시 차량 수, 틱 지연) 수치  

## 10. 레포·아티팩트 이름

- 레포 경로: `C:\Users\ryudw\source\ptr`
- Gradle root / artifact: `ptr` (예: `com.ptr`, 모듈 `ptr-etl`, `ptr-orchestrator`, …)
- Docker compose 프로젝트명: `ptr`
- Redis key prefix: `ptr:sim:{runId}:…`

데이터 원본은 레포 밖(OneDrive). 레포에는 샘플 fixture·생성 CSV/flows만 커밋 (대용량 xlsx는 `.gitignore`).
