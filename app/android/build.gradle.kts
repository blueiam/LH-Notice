// ▼▼▼ 이 buildscript 블록을 맨 위에 추가해야 합니다! ▼▼▼
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Flutter 프로젝트 기본 설정 (기존에 있었다면 유지, 없었다면 추가)
        classpath("com.android.tools.build:gradle:8.2.1") // 버전은 다를 수 있음
        
        // ★ Firebase 연동을 위한 필수 코드 (Kotlin DSL 문법) ★
        classpath("com.google.gms:google-services:4.4.2")
    }
}
// ▲▲▲ 여기까지 추가 ▲▲▲

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}