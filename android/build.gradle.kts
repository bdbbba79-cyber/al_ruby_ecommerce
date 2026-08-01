import com.android.build.gradle.BaseExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val projectPath = project.projectDir.absolutePath
    val buildPath = newBuildDir.asFile.absolutePath
    val sameDrive = if (projectPath.contains(":") && buildPath.contains(":")) {
        projectPath.substringBefore(":").equals(buildPath.substringBefore(":"), ignoreCase = true)
    } else {
        true
    }
    if (sameDrive) {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

fun Project.configureAndroid() {
    if (plugins.hasPlugin("com.android.application") ||
        plugins.hasPlugin("com.android.library")) {
        val android = extensions.findByName("android") as? BaseExtension
        android?.compileSdkVersion(36)
    }
}

subprojects {
    if (state.executed) {
        configureAndroid()
    } else {
        afterEvaluate {
            configureAndroid()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
