val newBuildDir = File(rootProject.projectDir, "../build")
rootProject.layout.buildDirectory.set(newBuildDir)

rootProject.extra.set("kotlin_version", "2.2.0")

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    val projectBuildDir = File(newBuildDir, project.name)
    layout.buildDirectory.set(projectBuildDir)
    project.evaluationDependsOn(":app")

    // Auto-fix namespace for old Flutter plugins
    fun fixPlugin() {
        val androidExt = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        if (androidExt != null) {
            // Fix Namespace
            if (androidExt.namespace == null) {
                androidExt.namespace = "com.${project.name.replace("-", "_").replace(".", "_")}"
            }
        }
    }

    if (project.state.executed) {
        fixPlugin()
    } else {
        afterEvaluate { 
            fixPlugin()
            // Force all plugins to use the same SDK version as the main app
            val androidExt = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            androidExt?.compileSdkVersion(35)
        }
    }

    configurations.all {
        resolutionStrategy {
            force("androidx.core:core:1.13.1")
            force("androidx.core:core-ktx:1.13.1")
            force("org.jetbrains.kotlin:kotlin-stdlib:2.2.0")
            force("org.jetbrains.kotlin:kotlin-stdlib-jdk7:2.2.0")
            force("org.jetbrains.kotlin:kotlin-stdlib-jdk8:2.2.0")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
