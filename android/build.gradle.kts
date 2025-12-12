plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

group = "uz.shs.better_player_plus"
version = "1.0-SNAPSHOT"

val lifecycleVersion = "2.9.4"
val annotationVersion = "1.9.1"
val media3Version = "1.8.0"
val workVersion = "2.10.5"

android {
    namespace = "uz.shs.better_player_plus"
    compileSdk = 36

    configurations.all {
        resolutionStrategy {
            // Принудительно используем единую версию Media3 для всех модулей
            force("androidx.media3:media3-exoplayer:$media3Version")
            force("androidx.media3:media3-extractor:$media3Version")
            force("androidx.media3:media3-common:$media3Version")
            force("androidx.media3:media3-datasource:$media3Version")
            force("androidx.media3:media3-ui:$media3Version")
            force("androidx.media3:media3-session:$media3Version")
            force("androidx.media3:media3-container:$media3Version")
        }
    }

    defaultConfig {
        minSdk = 24
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
        }
    }

    sourceSets["main"].java.srcDirs("src/main/kotlin")
}

dependencies {
    // Required for MediaSessionCompat, MediaMetadataCompat, PlaybackStateCompat
    implementation("androidx.media:media:1.7.1")
    implementation("androidx.appcompat:appcompat:1.7.0")

    // Media3 full modern stack (single version)
    implementation("androidx.media3:media3-exoplayer:$media3Version")
    implementation("androidx.media3:media3-exoplayer-hls:$media3Version")
    implementation("androidx.media3:media3-exoplayer-dash:$media3Version")
    implementation("androidx.media3:media3-exoplayer-smoothstreaming:$media3Version")
    implementation("androidx.media3:media3-datasource-cronet:$media3Version")
    implementation("androidx.media3:media3-extractor:$media3Version")
    implementation("androidx.media3:media3-ui:$media3Version")
    implementation("androidx.media3:media3-session:$media3Version")
    implementation("androidx.media3:media3-common:$media3Version")
    implementation("androidx.media3:media3-container:$media3Version")

    implementation("androidx.lifecycle:lifecycle-runtime-ktx:$lifecycleVersion")
    implementation("androidx.lifecycle:lifecycle-common:$lifecycleVersion")
    implementation("androidx.lifecycle:lifecycle-common-java8:$lifecycleVersion")

    implementation("androidx.annotation:annotation:$annotationVersion")
    implementation("androidx.work:work-runtime:$workVersion")

    //noinspection GradleDependency
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:2.2.20")
}
