// Top-level build file where you can add configuration options common to all sub-projects/modules.

buildscript {
    // Define versions in a Kotlin DSL compatible way
    val kotlinVersion = "1.9.22" // You can update this version if required
    
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.2.0")  // Ensure this is the latest version compatible with your Gradle
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
        classpath("com.google.gms:google-services:4.4.2")
        // Add Google Services if using Firebase
        // classpath("com.google.gms:google-services:4.4.0")
    }
}

allprojects {
    repositories {
        google()  // Make sure this is here
        mavenCentral()
        // jcenter()  // Optional, but may help with some older dependencies
        maven { url = uri("https://jitpack.io") }
    }
}

// Custom build directory configuration
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
    
    // Add common configurations for all subprojects
    afterEvaluate {
        if (plugins.hasPlugin("com.android.application") || plugins.hasPlugin("com.android.library")) {
            extensions.configure<com.android.build.gradle.BaseExtension> {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_11 // Set Java compatibility to Java 11
                    targetCompatibility = JavaVersion.VERSION_11 // Set target compatibility to Java 11
                }
                
                // Kotlin JVM target compatibility
                tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
                    kotlinOptions {
                        jvmTarget = "11"  // Set Kotlin compatibility to JVM 11
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
