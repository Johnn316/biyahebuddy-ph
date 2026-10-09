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
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// whisper_ggml 2.7.1 pins NDK 29.0.13113456 = r29 beta 1 (preview license).
// Build it with the app's stable NDK instead. Registered before the plugin's
// own afterEvaluate, so AGP sees this version.
subprojects {
    if (name == "whisper_ggml") {
        afterEvaluate {
            extensions.getByType<com.android.build.gradle.BaseExtension>()
                .ndkVersion = "28.2.13676358"
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
