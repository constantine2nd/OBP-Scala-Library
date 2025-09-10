name := "OBP-Scala-Library"

version := "0.1.0-SNAPSHOT"

scalaVersion := "2.13.14"

crossScalaVersions := Seq("2.12.17", "2.13.14", "3.3.1")

libraryDependencies ++= Seq(
  "org.scalatest" %% "scalatest" % "3.2.19" % Test
)

// Publishing configuration
// Choose one of the following options:

// Option 1: Local file-based repository (for development/testing)
// publishTo := Some(Resolver.file("local-repo", file("/workspace/target/local-repo")))

// Option 2: Nexus Repository (uncomment to use Nexus instead)
//*
publishTo := {
  val nexus = sys.env.getOrElse("NEXUS_URL", "http://localhost:8081/")
  if (isSnapshot.value)
    Some(("snapshots" at nexus + "repository/maven-snapshots/").withAllowInsecureProtocol(true))
  else
    Some(("releases" at nexus + "repository/maven-releases/").withAllowInsecureProtocol(true))
}

// Credentials for Nexus repository (required when using Option 2)
// Option A: Using environment variables (recommended for security)
credentials ++= {
  val nexusUsername = sys.env.get("NEXUS_USERNAME")
  val nexusPassword = sys.env.get("NEXUS_PASSWORD")
  val nexusHost = sys.env.getOrElse("NEXUS_HOST", "nexus")

  (nexusUsername, nexusPassword) match {
    case (Some(username), Some(password)) =>
      Seq(Credentials("Sonatype Nexus Repository Manager", nexusHost, username, password))
    case _ =>
      println("Warning: NEXUS_USERNAME and/or NEXUS_PASSWORD environment variables not set")
      println("Falling back to hardcoded credentials (not recommended for production)")
      Seq(Credentials("Sonatype Nexus Repository Manager", "nexus", "admin", "20b05303-d54d-434e-8aa6-48cc9ed3de20"))
  }
}

// Option B: Using credentials file (alternative secure approach)
// Uncomment the line below and comment out Option A if you prefer using a credentials file
// credentials += Credentials(Path.userHome / ".sbt" / ".credentials")
//*/

// Version scheme for compatibility
ThisBuild / versionScheme := Some("early-semver")

// Publishing configuration
ThisBuild / publishConfiguration := publishConfiguration.value.withOverwrite(true)
ThisBuild / publishLocalConfiguration := publishLocalConfiguration.value.withOverwrite(true)

// Organization and metadata
ThisBuild / organization := "org.openbankproject"
ThisBuild / organizationName := "Open Bank Project"
ThisBuild / organizationHomepage := Some(url("https://www.openbankproject.com/"))

ThisBuild / scmInfo := Some(
  ScmInfo(
    url("https://github.com/OpenBankProject/OBP-Scala-Library"),
    "scm:git@github.com:OpenBankProject/OBP-Scala-Library.git"
  )
)

ThisBuild / developers := List(
  Developer(
    id    = "obp-team",
    name  = "Open Bank Project Team",
    email = "contact@openbankproject.com",
    url   = url("https://github.com/OpenBankProject")
  )
)

ThisBuild / description := "Open Bank Project Scala Library"
ThisBuild / licenses := List("AGPL-3.0" -> new URL("https://www.gnu.org/licenses/agpl-3.0.en.html"))
ThisBuild / homepage := Some(url("https://github.com/OpenBankProject/OBP-Scala-Library"))

// Additional publishing settings
publishMavenStyle := true
Test / publishArtifact := false
pomIncludeRepository := { _ => false }

// Cross-compilation settings
crossPaths := true
autoScalaLibrary := true
