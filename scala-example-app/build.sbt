name := "scala-example-app"

version := "0.1.0"

scalaVersion := "2.13.14"

// Library is available via publishLocal in Docker environment
// No additional resolvers needed for local Ivy repository

libraryDependencies += "org.openbankproject" %% "obp-scala-library" % "0.1.0"
