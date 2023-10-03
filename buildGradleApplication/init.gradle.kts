var repositoryLocation = System.getenv("MAVEN_SOURCE_REPOSITORY");
fun RepositoryHandler.replaceRepositories() {
    clear()
    maven(repositoryLocation) {
        name = "Offline Maven Repository generated by buildGradleApplication"
        metadataSources {
            gradleMetadata()
            mavenPom()
            artifact()
        }
    }
}

gradle.beforeSettings {
    // Add the offline repository before settings are evaluated to ensure that it can be used for settings plugins (eg. gradle-enterprise)
    logger.lifecycle("Adding maven repository in $this: ${repositoryLocation}...")
    settings.pluginManagement.repositories.replaceRepositories()
}
gradle.settingsEvaluated {
    // Ensure that only the offline repository is used.
    logger.lifecycle("Replace all Maven repositories in $this with ${repositoryLocation}...")
    settings.pluginManagement.repositories.replaceRepositories()
    settings.dependencyResolutionManagement.repositories.replaceRepositories()
}
