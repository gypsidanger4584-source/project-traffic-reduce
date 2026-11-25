plugins {
    id("org.springframework.boot")
}

dependencies {
    implementation(project(":ptr-domain"))
    implementation(project(":ptr-etl"))
    implementation(project(":ptr-grid"))
    implementation(project(":ptr-vehicle"))
    implementation(project(":ptr-metrics"))

    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-data-redis")
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    // Boot 3.3: starter-flyway 없음 → core + DB 모듈 (BOM이 버전 관리)
    implementation("org.flywaydb:flyway-core")
    runtimeOnly("org.flywaydb:flyway-database-postgresql")

    runtimeOnly("org.postgresql:postgresql")
    runtimeOnly("com.h2database:h2")
}

tasks.named<org.springframework.boot.gradle.tasks.bundling.BootJar>("bootJar") {
    archiveBaseName.set("ptr-orchestrator")
}
