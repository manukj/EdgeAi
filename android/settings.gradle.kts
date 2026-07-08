pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
    plugins {
        id("com.android.library") version "8.11.1"
        id("org.jetbrains.kotlin.android") version "2.2.20"
    }
}

dependencyResolutionManagement {
    repositories {
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
        google()
        mavenCentral()
    }
}

rootProject.name = "edge_genai"