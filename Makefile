# Makefile
BASE_IMAGE=fel-python-base
RUNTIME_NAME=fel-python-runtime
APP_NAME=my-app

# images
base-build:
	docker build -f docker/docker_base/base.Dockerfile -t $(BASE_IMAGE):latest .

base-save:
	docker save -o docker/images/$(BASE_IMAGE).tar $(BASE_IMAGE):latest

base-load:
	docker load -i docker/images/$(BASE_IMAGE).tar

# development
runtime-build:
	docker build -f docker/docker_runtime/runtime.Dockerfile -t $(RUNTIME_NAME):latest .

runtime-save:
	docker save -o docker/images/$(RUNTIME_NAME).tar $(RUNTIME_NAME):latest

runtime-load:
	docker load -i docker/images/$(RUNTIME_NAME).tar

# production
app-build:
	docker build -f docker/docker_app/app.Dockerfile -t $(APP_NAME):latest .

app-save:
	docker save -o docker/images/$(APP_NAME).tar $(APP_NAME):latest

app-load:
	docker load -i docker/images/$(APP_NAME).tar

# containers 
app-run:
	docker run --rm -p 8000:8000 $(APP_NAME):latest

# compose 
runtime-up:
	docker compose -f docker-compose_runtime.yaml up -d

runtime-down:
	docker compose -f docker-compose_runtime.yaml down

app-up:
	docker compose -f docker-compose_app.yaml up -d

app-down:
	docker compose -f docker-compose_app.yaml down

runtime-logs:
	docker compose -f docker-compose_runtime.yaml logs -f

app-logs:
	docker compose -f docker-compose_app.yaml logs -f