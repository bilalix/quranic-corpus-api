# Stage 1: Build the application
FROM eclipse-temurin:17-jdk-alpine AS build

# Set the working directory inside the container
WORKDIR /app

# Copy the entire project directory
COPY . .

# Ensure the Gradle wrapper is executable
RUN chmod +x ./gradlew

# # Use Docker secrets for GITHUB_TOKEN
# RUN --mount=type=secret,id=github_token \
#     GITHUB_TOKEN=$(cat /run/secrets/github_token) ./gradlew build -x test --no-daemon

# Pass the GITHUB_TOKEN as a build argument and set it as an environment variable
ARG GITHUB_TOKEN
ENV GITHUB_TOKEN=${GITHUB_TOKEN}

# Build the application
RUN ./gradlew shadowJar --no-daemon

# Stage 2: Create the runtime image
FROM eclipse-temurin:17-jre-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy the built JAR file from the build stage
COPY --from=build /app/build/libs/*-all.jar app.jar

# Expose the default Micronaut port
EXPOSE 6382

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]