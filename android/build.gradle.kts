val newBuildDir = File(rootProject.projectDir, "../build")
rootProject.layout.buildDirectory.set(newBuildDir)

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
        afterEvaluate { fixPlugin() }
    }

    configurations.all {
        resolutionStrategy {
            force("androidx.core:core:1.13.1")
            force("androidx.core:core-ktx:1.13.1")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
