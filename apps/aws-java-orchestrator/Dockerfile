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
RUN mkdir -p /opt/extensions

RUN curl -L \
  https://github.com/awslabs/aws-lambda-web-adapter/releases/download/v0.8.5/aws-lambda-web-adapter \
  -o /opt/extensions/aws-lambda-web-adapter \
  && chmod +x /opt/extensions/aws-lambda-web-adapter

COPY --from=build /app/build/libs/app.jar ${LAMBDA_TASK_ROOT}

ENV AWS_LAMBDA_EXEC_WRAPPER=/opt/extensions/aws-lambda-web-adapter
ENV PORT=8080

CMD ["org.springframework.boot.loader.launch.JarLauncher"]
