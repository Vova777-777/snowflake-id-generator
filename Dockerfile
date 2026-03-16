# ============================================================
# Build stage
# ============================================================
FROM eclipse-temurin:21-jdk-jammy AS builder

WORKDIR /app

# Копируем файлы для кэширования зависимостей
COPY build.gradle.kts settings.gradle.kts gradlew ./
COPY gradle gradle

# Скачиваем зависимости (без подавления ошибок!)
ENV GRADLE_OPTS="-Dorg.gradle.internal.http.connectionTimeout=60000 -Dorg.gradle.internal.http.socketTimeout=60000"
RUN ./gradlew dependencies --no-daemon

# Копируем исходный код
COPY src src

# Сборка проекта
RUN ./gradlew build -x test -x ktlintKotlinScriptCheck -x ktlintMainSourceSetCheck -x ktlintTestSourceSetCheck

# ============================================================
# Runtime stage
# ============================================================
FROM eclipse-temurin:21-jre-jammy

WORKDIR /app

# Создаём пользователя с минимальными правами
RUN useradd --system --uid 1001 appuser

# Копируем JAR из builder
COPY --from=builder /app/build/libs/*.jar app.jar

# Передаем права
RUN chown -R appuser:appuser /app
USER appuser

# Порт (если есть API)
EXPOSE 8080

# Запуск
ENTRYPOINT ["java", "-jar", "app.jar"]