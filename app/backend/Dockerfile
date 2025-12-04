FROM maven:3.9-eclipse-temurin-17-alpine AS build
WORKDIR /app
COPY pom.xml .
# Download dependencies first (for caching)
RUN mvn dependency:go-offline -B
COPY src src
RUN mvn -Dmaven.test.skip=true package -B

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
# Create non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY --from=build /app/target/ems-backend-0.0.1-SNAPSHOT.jar app.jar
RUN chown appuser:appgroup app.jar
USER appuser
EXPOSE 8080
ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-jar", "/app/app.jar"]
