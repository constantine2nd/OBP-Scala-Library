# Java Example App

This is a simple Java application that demonstrates how to use the OBP Scala Library from Java code.

## Requirements

### Docker Environment
- Docker and Docker Compose
- OBP Scala Library Docker setup running
- **Note**: Maven is not available in the SBT Docker container

### Native Environment (Recommended for Java)
- Maven 3.9+
- Java 17+
- OBP Scala Library published to local repository

## Setup and Usage

### Native Environment (Recommended)

1. **First, publish the main library locally**:
   ```bash
   cd ..
   sbt +publishLocal
   ```

2. **Compile and run the example application**:
   ```bash
   mvn compile exec:java
   ```

   Or specify the main class explicitly:
   ```bash
   mvn compile exec:java -Dexec.mainClass="com.example.app.MainApp"
   ```

   Expected output:
   ```
   Hello, Java Developer from OBP Scala Library!
   ```

### Docker Environment (Limited Support)

**Note**: The SBT Docker container doesn't include Maven. For Docker-based Java development, you would need to:

1. **Set up the Docker environment**:
   ```bash
   cd ../docker
   ./start-dev.sh
   ```

2. **Option A: Manual Java compilation** (inside Docker container):
   ```bash
   # This is complex and not recommended - use native environment instead
   docker exec sbt bash -c "cd /workspace/java-example-app && ..."
   ```

3. **Option B: Extend Docker setup** (add Maven to container):
   - Modify `docker/sbt/Dockerfile` to include Maven
   - Rebuild containers

**Recommendation**: Use the native environment for Java development, as it provides better tooling support.

## Configuration

The `pom.xml` file is configured to:
- Use Java 17
- Look for the OBP Scala Library in multiple repositories (local file and Nexus)
- Include both the Scala library and Scala runtime dependencies
- Use Maven compiler and exec plugins

## Dependencies

The project depends on:
- `org.openbankproject:obp-scala-library_2.13:0.1.0` - The main library
- `org.scala-lang:scala-library:2.13.14` - Scala runtime (required for Java interop)

## Usage in Your Own Java Projects

### Native Environment
To use the OBP Scala Library in your own Java/Maven projects, add this to your `pom.xml`:

```xml
<!-- After running: sbt +publishLocal -->
<dependencies>
  <dependency>
    <groupId>org.openbankproject</groupId>
    <artifactId>obp-scala-library_2.13</artifactId>
    <version>0.1.0</version>
  </dependency>
  <dependency>
    <groupId>org.scala-lang</groupId>
    <artifactId>scala-library</artifactId>
    <version>2.13.14</version>
  </dependency>
</dependencies>
```

### Docker Environment (Advanced)
```xml
<repositories>
  <repository>
    <id>local-file-repo</id>
    <name>Local File Repository</name>
    <url>file:///workspace/target/local-repo</url>
  </repository>
  <repository>
    <id>local-nexus</id>
    <name>Local Nexus Repository</name>
    <url>http://nexus:8081/repository/maven-releases/</url>
  </repository>
</repositories>

<dependencies>
  <dependency>
    <groupId>org.openbankproject</groupId>
    <artifactId>obp-scala-library_2.13</artifactId>
    <version>0.1.0</version>
  </dependency>
  <dependency>
    <groupId>org.scala-lang</groupId>
    <artifactId>scala-library</artifactId>
    <version>2.13.14</version>
  </dependency>
</dependencies>
```

## Scala Cross-Compilation Notes

- The artifact name includes the Scala version: `obp-scala-library_2.13`
- For other Scala versions, use: `obp-scala-library_2.12` or `obp-scala-library_3`
- Always include the corresponding `scala-library` dependency

## Troubleshooting

### Native Environment
If the library is not found:
1. Make sure you've published it locally: `cd .. && sbt +publishLocal`
2. Verify the library version and Scala version match what's expected
3. Check that Maven can access the local repository: `mvn dependency:tree`

### Docker Environment
If attempting to use Docker (not recommended for Java):
1. Ensure Docker containers are running: `docker-compose ps`
2. Check that the library is published in Docker: `docker exec sbt bash -c "cd /workspace && sbt +publishLocal"`
3. Test repository connectivity: `curl http://localhost:8081/repository/maven-releases/`

### General Issues
If you get `ClassNotFoundException`:
1. Ensure the Scala runtime dependency is included
2. Check that the Java classpath includes all required JAR files
3. Verify compatibility between Java 17 and Scala 2.13

### Recommendation
For Java development, use the **native environment** with Maven installed locally. The Docker environment is optimized for Scala development and doesn't include Maven by default.