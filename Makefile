APP_VERSION?="$(shell cd backend-project-template && ./mvnw help:evaluate -Dexpression=project.version -q -DforceStdout)"

DOCKER_COMPOSE_FILE_PATH?="docker/docker-compose.yaml"

PROJECT_NAME?="$(shell basename ${PWD})"

restart: stop start

# Add after configuring Docker plugin on Maven

# rebuild: clean docker start

# docker:
# 	@./mvnw clean package -DskipTests

compile:
	@echo "Compiling backend-project-template"
    ifeq ($(PROJECT_NAME), backend-project-template)
		@./mvnw clean package -DskipTests
    else ifeq ($(PROJECT_NAME), frontend-project-template)
		@cd ../backend-project-template/ && ./mvnw clean package -DskipTests
    else
		@cd backend-project-template/ && ./mvnw clean package -DskipTests
    endif

run:
	@./mvnw spring-boot:run

start:
	@echo "Starting containers..."
	@echo "App version: $(APP_VERSION)"
	@APP_VERSION=$(APP_VERSION) docker-compose -f ${DOCKER_COMPOSE_FILE_PATH} up -d

create-network:
	@echo "Creating network 'development'..."
	@docker network create --gateway 172.28.0.1 --subnet 172.28.0.0/16 development 2>/dev/null; true
	@docker network ls

stop:
	@echo "Stopping containers..."
	@docker-compose -f ${DOCKER_COMPOSE_FILE_PATH} stop

clean: soft-clean
	@echo "Deleting named volumes..."
	@docker volume rm docker_postgres-data
	@docker volume rm docker_pgadmin4-data 

soft-clean: stop 
	@docker-compose -f ${DOCKER_COMPOSE_FILE_PATH} rm -f -v

status:
	@docker-compose -f ${DOCKER_COMPOSE_FILE_PATH} ps

generate-properties:
	@echo "Generating 'application.properties'"
	@if [ "$(PROJECT_NAME)" = "backend-project-template" ]; then \
		rm src/main/resources/application.properties && \
		cp -n src/main/resources/application.properties.sample src/main/resources/application.properties; \
	elif [ "$(PROJECT_NAME)" = "frontend-project-template" ]; then \
		cd ../backend-project-template/ && \
		rm src/main/resources/application.properties && \
		cp -n src/main/resources/application.properties.sample src/main/resources/application.properties; \
	else \
		cd backend-project-template/ && \
		rm src/main/resources/application.properties && \
		cp -n src/main/resources/application.properties.sample src/main/resources/application.properties; \
	fi;

setup:
	-$(MAKE) clean
	$(MAKE) create-network
	$(MAKE) generate-properties
	$(MAKE) start
	$(MAKE) compile