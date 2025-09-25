FROM openjdk:17-jdk-slim

WORKDIR /app

COPY note-service/target/note-service-1.0.0.jar app.jar

EXPOSE 8082

ENTRYPOINT ["java", "-jar", "app.jar"]
