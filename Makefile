# Makefile
BASE_IMAGE=fel-python-base
RUNTIME_NAME=fel-python-runtime
APP_NAME=my-app

# images
build-base:
	docker build -f docker/docker_base/base.Dockerfile -t $(BASE_IMAGE):latest .

save-base:
	docker save -o docker/images/$(BASE_IMAGE).tar $(BASE_IMAGE):latest

load-base:
	docker load -i docker/images/$(BASE_IMAGE).tar

# development
build-runtime:
	docker build -f docker/docker_runtime/runtime.Dockerfile -t $(RUNTIME_NAME):latest .

save-runtime:
	docker save -o docker/images/$(RUNTIME_NAME).tar $(RUNTIME_NAME):latest

load-runtime:
	docker load -i docker/images/$(RUNTIME_NAME).tar

# production
build-app:
	docker build -f docker/docker_app/app.Dockerfile -t $(APP_NAME):latest .

save-app:
	docker save -o docker/images/$(APP_NAME).tar $(APP_NAME):latest

load-app:
	docker load -i docker/images/$(APP_NAME).tar

# containers 
run:
	docker run --rm -p 8000:8000 $(APP_NAME):latest

# compose 
up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f
