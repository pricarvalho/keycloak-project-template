APP_VERSION?="$(shell cd backend-project-template && ./mvnw help:evaluate -Dexpression=project.version -q -DforceStdout)"

BACKEND_DOCKER_COMPOSE_FILE_PATH?="backend-project-template/docker/docker-compose.yaml"
FRONTEND_DOCKER_COMPOSE_FILE_PATH?="frontend-project-template/docker/docker-compose.yaml"

PROJECT_NAME?="$(shell basename ${PWD})"

restart: stop start

run-backend:
	@cd backend-project-template && ./mvnw spring-boot:run

run-frontend:
	@cd frontend-project-template && npm start

setup:
	-$(MAKE) clean
	@echo "=====================START=============================="
	$(MAKE) create-network;
	@echo "======================================================="
	$(MAKE) start
	@echo "======================================================="
	$(MAKE) install-backend
	@echo "======================================================="
	$(MAKE) install-frontend
	@echo "=======================END============================="

#DOCKER
create-network:
	@echo "Creating network 'development'..."
	@docker network create --gateway 172.28.0.1 --subnet 172.28.0.0/16 development 2>/dev/null; true
	@docker network ls

start:
	@echo "Starting containers..."
	@echo "App version: $(APP_VERSION)"
	@APP_VERSION=$(APP_VERSION) docker-compose -f ${BACKEND_DOCKER_COMPOSE_FILE_PATH} -f ${FRONTEND_DOCKER_COMPOSE_FILE_PATH} up -d

stop:
	@echo "Stopping containers..."
	@docker-compose -f ${BACKEND_DOCKER_COMPOSE_FILE_PATH} -f ${FRONTEND_DOCKER_COMPOSE_FILE_PATH} stop

soft-clean: stop 
	@docker-compose -f ${BACKEND_DOCKER_COMPOSE_FILE_PATH} -f ${FRONTEND_DOCKER_COMPOSE_FILE_PATH} rm -f -v

clean: soft-clean
	@echo "Deleting named volumes..."
	@docker volume rm docker_my-app-postgres-data
	@docker volume rm docker_my-app-pgadmin4-data
	@docker volume rm docker_keycloak-postgres-data

status:
	@docker-compose -f ${BACKEND_DOCKER_COMPOSE_FILE_PATH} -f ${FRONTEND_DOCKER_COMPOSE_FILE_PATH} ps

#INSTALLING APPLICATIONS
install-backend: 
	@echo "Generating 'application.properties' and Intalling BACKEND Application"
		cd backend-project-template/ && \
		rm src/main/resources/application.properties && \
		cp -n src/main/resources/application.properties.sample src/main/resources/application.properties && \
		./mvnw clean package -DskipTests;

install-frontend:
	@echo "Intalling FRONTEND Application"
	@cd frontend-project-template && rm -rf node_modules && npm install