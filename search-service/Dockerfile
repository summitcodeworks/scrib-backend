FROM openjdk:17-jdk-slim

WORKDIR /app

COPY search-service/target/search-service-1.0.0.jar app.jar

EXPOSE 8083

ENTRYPOINT ["java", "-jar", "app.jar"]
