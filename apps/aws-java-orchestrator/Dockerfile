# -------- Build stage --------
FROM gradle:8.7-jdk21 AS build
WORKDIR /app
COPY build.gradle settings.gradle ./
COPY src ./src
RUN gradle bootJar --no-daemon

# -------- Lambda runtime --------
FROM public.ecr.aws/lambda/java:21
COPY --from=build /app/build/libs/app.jar ${LAMBDA_TASK_ROOT}

CMD ["org.springframework.boot.loader.launch.JarLauncher"]
