# Build stage
FROM gradle:8.7-jdk21 AS build
WORKDIR /app

# Copy Gradle wrapper & config
COPY gradlew .
COPY gradle gradle
COPY build.gradle settings.gradle ./

# Grant execute permission
RUN chmod +x gradlew

# Copy source
COPY src ./src

# Build Spring Boot jar
RUN ./gradlew bootJar --no-daemon

# Lambda runtime
FROM public.ecr.aws/lambda/java:21
COPY --from=build /app/build/libs/app.jar ${LAMBDA_TASK_ROOT}
CMD ["org.springframework.boot.loader.launch.JarLauncher"]
