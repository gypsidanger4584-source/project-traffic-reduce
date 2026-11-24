# PTR — Project Traffic Reduce

강남~양재 구간 V2V 협조 주행 시뮬레이션 백엔드.  
Java(Spring)가 그리드 통제·차량 인스턴스·메시징·ETL을 담당하고, SUMO는 Python TraCI 브리지로만 연동한다.

## 스택

- Java 17 / Spring Boot 3.3 / Spring Batch / JPA
- PostgreSQL 16, Redis 7 (Docker Compose)
- Python SUMO TraCI bridge (`sumo-bridge/`)
- Gradle multi-module (`com.ptr`)

## 모듈

| 모듈 | 역할 |
|------|------|
| `ptr-domain` | ERD / JPA |
| `ptr-etl` | TOPIS 엑셀 → 수요 프로파일 |
| `ptr-grid` | 셀 슬롯·진입 허가 |
| `ptr-vehicle` | 차량 인스턴스·의도 메시지 |
| `ptr-metrics` | 런 지표 |
| `ptr-orchestrator` | 시뮬 오케스트레이션 API (부트 앱) |
| `sumo-bridge/` | TraCI 어댑터 (Python) |

## 범위 (v1)

- 지점: D-35, D-38, D-34, D-37, B-17 / 싱크만 B-11·B-16
- 수요: 2025 월–금(공휴일 제외), 퇴근 17–19 우선
- 설계: `docs/superpowers/specs/2026-11-24-ptr-design.md`

## 로컬 실행

```bash
# 인프라
docker compose up -d

# 빌드
./gradlew build

# 앱 (DB·Redis 없이 스모크는 local 프로필)
./gradlew :ptr-orchestrator:bootRun --args='--spring.profiles.active=local'
```

원본 TOPIS xlsx는 레포 밖 OneDrive 경로를 쓰고, 대용량 엑셀은 커밋하지 않는다.

## Redis key prefix

`ptr:sim:{runId}:…`
