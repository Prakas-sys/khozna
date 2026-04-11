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

    // Auto-fix namespace for old Flutter plugins that don't declare it (e.g. flutter_app_badger)
    fun fixNamespace() {
        val androidExt = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        if (androidExt != null && androidExt.namespace == null) {
            androidExt.namespace = "com.${project.name.replace("-", "_").replace(".", "_")}"
        }
    }

    if (project.state.executed) {
        fixNamespace()
    } else {
        afterEvaluate { fixNamespace() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
