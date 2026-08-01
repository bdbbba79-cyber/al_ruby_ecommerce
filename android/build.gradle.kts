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
    val projectDrive = project.projectDir.absolutePath.substringBefore(":")
    val buildDrive = newBuildDir.asFile.absolutePath.substringBefore(":")
    if (projectDrive.equals(buildDrive, ignoreCase = true)) {
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
