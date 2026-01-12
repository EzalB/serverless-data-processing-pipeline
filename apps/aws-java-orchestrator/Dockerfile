# Build stage
FROM gradle:8.7-jdk21 AS build
WORKDIR /app

COPY gradlew .
COPY gradle gradle
COPY build.gradle settings.gradle ./
RUN chmod +x gradlew

COPY src ./src
RUN ./gradlew bootJar --no-daemon

#################

# Runtime stage
FROM public.ecr.aws/lambda/java:21
COPY --from=build /app/build/libs/app.jar ${LAMBDA_TASK_ROOT}

ADD https://github.com/awslabs/aws-lambda-web-adapter/releases/latest/download/aws-lambda-web-adapter /opt/extensions/aws-lambda-web-adapter
RUN chmod +x /opt/extensions/aws-lambda-web-adapter

ENV AWS_LAMBDA_EXEC_WRAPPER=/opt/extensions/aws-lambda-web-adapter
ENV PORT=8080

CMD ["org.springframework.boot.loader.launch.JarLauncher"]
