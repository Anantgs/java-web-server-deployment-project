# Use an official OpenJDK runtime as a base image
FROM eclipse-temurin:8-jre-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy the JAR file into the container at /app
COPY target/web-server-example-1.0-SNAPSHOT-jar-with-dependencies.jar /app/

# Expose the port the app runs on
EXPOSE 8080

# Command to run your application
CMD ["java", "-jar", "web-server-example-1.0-SNAPSHOT-jar-with-dependencies.jar"]