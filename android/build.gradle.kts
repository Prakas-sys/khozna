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

    // Auto-fix namespace and SDK for old Flutter plugins
    fun fixPlugin() {
        val androidExt = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        if (androidExt != null) {
            // Fix Namespace
            if (androidExt.namespace == null) {
                androidExt.namespace = "com.${project.name.replace("-", "_").replace(".", "_")}"
            }
            // Fix SDK Version (Force 34 for lStar compatibility)
            if (androidExt.compileSdkVersion == null || androidExt.compileSdkVersion!!.contains("31") || androidExt.compileSdkVersion!!.contains("30")) {
                androidExt.compileSdkVersion(34)
            }
        }
    }

    if (project.state.executed) {
        fixPlugin()
    } else {
        afterEvaluate { fixPlugin() }
    }

    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "androidx.core" && (requested.name == "core-ktx" || requested.name == "core")) {
                useVersion("1.13.1")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
