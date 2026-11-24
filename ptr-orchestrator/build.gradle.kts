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

    runtimeOnly("org.postgresql:postgresql")
    runtimeOnly("com.h2database:h2")
}

tasks.named<org.springframework.boot.gradle.tasks.bundling.BootJar>("bootJar") {
    archiveBaseName.set("ptr-orchestrator")
}
