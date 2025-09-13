# Running the Backend Inside Docker

Follow these steps to test if the Dockerized app runs as expected:

### 1. **Build the Docker Image**
Run the following command in the terminal from the root of your project directory (where the Dockerfile is located):

```bash
docker build \
  --build-arg GITHUB_TOKEN=<YOUR-GITHUB-TOKEN> \
  --build-arg MICRONAUT_ENV=dev \
  -t quranic-corpus-api .
```

### 2. **Run the Docker Container**
Start a container from the built image:

```bash
docker run -p 6382:6382 quranic-corpus-api
```

This maps port `6382` of the container to port `6382` on your host machine. Adjust the port if your application uses a different one.

### 3. **Verify the Application**
- Open your browser or use a tool like `curl` or Postman to access the application at `http://localhost:6382`.
- Test it using `/metadata` endpoint for example:

```bash
curl http://localhost:6382/metadata

StatusCode        : 200
StatusDescription : OK
Content           : {"chapters":[{"chapterNumber":1,"verseCount":7,"phonetic":"Al-FÄtiá¸¥ah","translation":"The Opening","city":"Makkah"},...
```

### 4. **Check Logs**
If the application doesn't behave as expected, check the container logs for errors:

```bash
docker logs <container_id>
```

Replace `<container_id>` with the ID of the running container, which you can find using:

```bash
docker ps
```

# Debugging

## General Debugging

Follow these steps to debug what's happening inside the Docker containe:

---

### 1. **Start the Container in Interactive Mode**
Run the container with an interactive shell instead of starting the application immediately:

```bash
sudo docker run -it --entrypoint /bin/sh quranic-corpus-api
```

This will give you access to the container's shell, where you can inspect the files and environment.

---

### 2. **Inspect the JAR File**
Once inside the container, check if the `app.jar` file exists and inspect its contents:

```bash
ls -l /app
```

If the `app.jar` file exists, inspect its `MANIFEST.MF` file to verify the `Main-Class` attribute:

```bash
unzip -p app.jar META-INF/MANIFEST.MF
```

You should see a `Main-Class` attribute like this:

```
Main-Class: app.qurancorpus.Application
```

If the `Main-Class` attribute is missing, it means the JAR was not built correctly.

---

### 3. **Check Environment Variables**
Verify that the `GITHUB_TOKEN` environment variable is set correctly (if applicable):

```bash
echo $GITHUB_TOKEN
```

---

### 4. **Manually Run the Application**
Try running the application manually inside the container to see if it starts correctly:

```bash
java -jar app.jar
```

If it fails, the error message will provide more details about what went wrong.

---

### 5. **Inspect Build Artifacts**
If the `app.jar` file is missing or incorrect, you can inspect the build artifacts in the `build/libs` directory:

```bash
ls -l /app/build/libs
```

This will help you determine if the JAR file was built correctly during the build stage.

---

### 6. **Rebuild the Image with Debugging**
You can add debugging steps to your Dockerfile to inspect the build process. For example, add a temporary `RUN` command to list the contents of the `build/libs` directory after the build:

```dockerfile
RUN ./gradlew clean build --no-daemon && ls -l build/libs
```

Rebuild the image and check the output during the build process:

```bash
docker build -t quranic-corpus-api .
```

---

### 7. **Check Docker Logs**
If the container exits immediately after starting, check the logs for more details:

```bash
sudo docker logs <container_id>
```

Replace `<container_id>` with the ID of the container, which you can find using:

```bash
sudo docker ps -a
```

---

### 8. **Run the Build Locally**
If the issue persists, try running the build locally (outside Docker) to verify that the JAR is being built correctly:

```bash
./gradlew clean build
```

Inspect the `build/libs` directory to ensure the JAR file is present and contains the correct `MANIFEST.MF`.

---

### 9. **Enable Debugging in Gradle**
You can enable Gradle debugging in the Dockerfile to get more detailed logs during the build:

```dockerfile
RUN ./gradlew clean build --no-daemon --debug
```

Rebuild the image and check the output for any issues.

## Debugging Environment Variables

The command `./gradlew run -Dmicronaut.environments=local` should work if your Micronaut application is properly configured to recognize the `local` environment. If it doesn't work, here are some possible reasons and how to fix them:

---

### 1. **Environment Not Recognized**
Micronaut uses the `-Dmicronaut.environments` property to activate specific environment configurations. Ensure that you have a configuration file or settings for the `local` environment.

#### Check Your Configuration Files
Make sure you have a configuration file like `application-local.yml` in your resources directory. For example:

```yaml
micronaut:
  application:
    name: quranic-corpus-api
  server:
    port: 6382
```

If this file is missing, Micronaut won't recognize the `local` environment, and the application will fall back to the default configuration.

---

### 2. **Gradle `run` Task Not Passing JVM Arguments**
The `run` task in Gradle may not pass the `-Dmicronaut.environments` argument to the JVM by default. To fix this, you can explicitly configure the `run` task in your build.gradle file:

```gradle
tasks.named('run') {
    jvmArgs '-Dmicronaut.environments=local'
}
```

Alternatively, you can pass the argument directly to the `run` task using `--args`:

```bash
./gradlew run --args="-Dmicronaut.environments=local"
```

---

### 3. **Using the Wrong Command**
The `run` task is typically used for development purposes. If you're trying to run the application in a production-like environment, you should use the `shadowJar` task to build a fat JAR and then run it with `java -jar`.

For example:
1. Build the fat JAR:
   ```bash
   ./gradlew shadowJar
   ```

2. Run the JAR with the `local` environment:
   ```bash
   java -Dmicronaut.environments=local -jar build/libs/quranic-corpus-api-all.jar
   ```

---

### 4. **Verify the Environment Activation**
Add a log statement in your `Application` class to verify which environment is active. For example:

```java
package app.qurancorpus;

import io.micronaut.context.env.Environment;
import io.micronaut.runtime.Micronaut;

public class Application {
    public static void main(String[] args) {
        Micronaut.run(Application.class, args)
                 .getEnvironment()
                 .getActiveNames()
                 .forEach(env -> System.out.println("Active environment: " + env));
    }
}
```

When you run the application, it should print `Active environment: local` if the `local` environment is correctly activated.

---

### 5. **Check for Errors**
If the application still doesn't work, check the logs for errors. Common issues include:
- Missing configuration files for the `local` environment.
- Incorrect JVM arguments.
- Dependency injection errors caused by environment-specific beans.

---

### 6. **Running in Docker**
If you're running the application in Docker, ensure the `MICRONAUT_ENV` argument is passed correctly in the Dockerfile or at runtime:

```bash
docker run -p 6382:6382 -e MICRONAUT_ENV=local quranic-corpus-api
```
