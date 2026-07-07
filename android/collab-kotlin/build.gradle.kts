plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.kotlin.serialization)
}

dependencies {
    implementation(project(":core-model"))
    implementation(libs.kotlinx.serialization.json)
    implementation(libs.okhttp)
    testImplementation(libs.junit)
}

kotlin {
    jvmToolchain(17)
}
