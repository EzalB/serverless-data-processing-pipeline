# Build stage
FROM gradle:8.7-jdk21 AS build
WORKDIR /app

COPY gradlew .
COPY gradle gradle
COPY build.gradle settings.gradle ./
RUN chmod +x gradlew

COPY src ./src
RUN ./gradlew build --no-daemon

#################

# Runtime stage
FROM public.ecr.aws/lambda/java:21

COPY --from=build /app/build/libs/app.jar ${LAMBDA_TASK_ROOT}

CMD ["com.ezalb.aws_java_orchestrator.handler.SqsEventHandler"]
