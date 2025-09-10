# Scala Example App

This is a simple Scala application that demonstrates how to use the OBP Scala Library.

## Requirements

### Docker Environment (Recommended)
- Docker and Docker Compose
- OBP Scala Library Docker setup running

### Native Environment
- SBT 1.9+
- Java 17+
- OBP Scala Library published to local repository

## Setup and Usage

### Docker Environment (Recommended)

1. **First, set up the Docker development environment**:
   ```bash
   cd ../docker
   ./start-dev.sh
   ```
   This automatically publishes the library and sets up everything needed.

2. **Run the Scala example**:
   ```bash
   # From the docker directory
   docker exec sbt bash -c "cd /workspace/scala-example-app && sbt run"
   ```

   Expected output:
   ```
   Hello, Scala Developer from OBP Scala Library!
   ```

### Native Environment

1. **First, publish the main library locally**:
   ```bash
   cd ..
   sbt +publishLocal
   ```

2. **Run the example application**:
   ```bash
   sbt run
   ```

   Expected output:
   ```
   Hello, Scala Developer from OBP Scala Library!
   ```

## Configuration

The `build.sbt` file is configured to:
- Use Scala 2.13.14 (default version)
- Depend on `org.openbankproject %% "obp-scala-library" % "0.1.0"`
- Use standard Ivy local repository (works in both Docker and native environments)

## Usage in Your Own Projects

### Native Environment
To use the OBP Scala Library in your own Scala projects, add this to your `build.sbt`:

```scala
// After running: sbt +publishLocal
libraryDependencies += "org.openbankproject" %% "obp-scala-library" % "0.1.0"
```

### Docker Environment
```scala
// Library available via Docker publishLocal
libraryDependencies += "org.openbankproject" %% "obp-scala-library" % "0.1.0"

// Or using Nexus repository:
resolvers += ("Local Nexus" at "http://nexus:8081/repository/maven-releases/").withAllowInsecureProtocol(true)
libraryDependencies += "org.openbankproject" %% "obp-scala-library" % "0.1.0"
```

## Troubleshooting

### Docker Environment
If the library is not found:
1. Make sure you've run the Docker setup: `cd ../docker && ./start-dev.sh`
2. Check that containers are running: `docker-compose ps`
3. Re-publish if needed: `docker exec sbt bash -c "cd /workspace && sbt +publishLocal"`

### Native Environment
If the library is not found:
1. Make sure you've published it locally: `cd .. && sbt +publishLocal`
2. Verify the library version matches what's expected
3. Check that SBT can find the local Ivy repository: `sbt "show libraryDependencies"`

## Note on Implementation

This example uses reflection to access the library due to some classpath complexities in the containerized environment. In a real project, you would typically use direct imports:

```scala
import com.openbankproject.library.MyLib

object MyApp {
  def main(args: Array[String]): Unit = {
    println(MyLib.hello("User"))
  }
}
```