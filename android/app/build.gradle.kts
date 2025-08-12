plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.shift.schedule.app"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"  // Set Kotlin JVM target to 11
    }

    // Explicit Java toolchain configuration
    java {
        toolchain {
            languageVersion.set(JavaLanguageVersion.of(11))  // Ensure using Java 11
        }
    }

    defaultConfig {
        applicationId = "com.shift.schedule.app"
        minSdk = 21
        targetSdk = 34
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            storeFile = file("your-release-key.keystore")  // Path to your keystore file
            storePassword = "root123"          // The password of your keystore
            keyAlias = "your-key-alias"                              // Alias of your key
            keyPassword = "root123"              // The password of your key
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    packagingOptions {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
            excludes += "META-INF/DEPENDENCIES"
            excludes += "META-INF/LICENSE*"
            excludes += "META-INF/NOTICE*"
            excludes += "META-INF/ASL2.0"
            excludes += "**/attach_hotspot_windows.dll"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("com.razorpay:checkout:1.6.33")
    implementation("com.google.android.gms:play-services-wallet:19.1.0")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.22")
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))
    implementation("com.google.firebase:firebase-analytics")

    // Alternative Google Pay implementation that doesn't require inapp-client-api
    implementation("com.google.android.gms:play-services-pay:16.3.0")

    implementation("com.android.billingclient:billing:5.1.0")
}
