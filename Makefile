.PHONY: build push shell run start stop rm release
default: build

IMG_NAME = lightdf_framework
VERSION = 0.1
DEV_DIR = /Users/andrew/Code/LightDF/lightdf_framework
CONTAINER_DIR = /usr/share/lightdf_framework/
CONTAINER_NAME = lightdf_framework
CONTAINER_BIN_DIR = /usr/bin
PORT_EXPOSE = 3000### Do not expose a port to the world in production - should only be accessible inside the container infrasctructure... but this access is needed for test.
PORT_INTERNAL = 3000
NODESERVER_APP_NAME = app.js
TEST_SCRIPT = test.js
JSHINT = /usr/local/bin/jshint
DOCKERHUB_UID = lightdf
API_DOCS_DIR = api_docs
LINK_TO_CONTAINER = lightdf_db# This is the way we connect docker containers together so that data is shared between them.

test_static:
	@echo "v---- Initiating static code test (using jshint, ES6) ----v"
	@$(JSHINT) --config .jshintrc *.js routes/*.js
	@if [ $$? -eq 0 ] ; then echo "Success: static test passed (jshint) - no errors" ; fi

test_dynamic:
	@echo "v---- Initiating dynamic node.js tests ----v"
	docker exec $(CONTAINER_NAME) $(CONTAINER_BIN_DIR)/node $(CONTAINER_DIR)/$(TEST_SCRIPT)

test: test_static test_dynamic

build: test_static
	@echo "v---- Building container ----v"
	docker build -t $(IMG_NAME):$(VERSION) $(DEV_DIR)

runDev:
	docker run -d --name $(CONTAINER_NAME) -p $(PORT_EXPOSE):$(PORT_INTERNAL) --link $(LINK_TO_CONTAINER):$(LINK_TO_CONTAINER) -v $(DEV_DIR):$(CONTAINER_DIR) $(IMG_NAME):$(VERSION)

runProd:
	docker run -d --name $(CONTAINER_NAME) --link $(LINK_TO_CONTAINER):$(LINK_TO_CONTAINER) $(IMG_NAME):$(VERSION)

stop:
	-docker stop $(CONTAINER_NAME)
	-docker rm $(CONTAINER_NAME)

start:
	docker start $(CONTAINER_NAME)

restart: stop run

rm:
	-docker rmi $(IMG_NAME):$(VERSION)
	-docker rmi $(DOCKERHUB_UID)/$(CONTAINER_NAME):$(VERSION)

clean:
	-docker images|grep \<none\>|awk '{print $$3}' | xargs docker rmi

shell:
	docker exec -it $(CONTAINER_NAME) /bin/sh

push:
	docker commit $(CONTAINER_NAME) $(DOCKERHUB_UID)/$(CONTAINER_NAME):$(VERSION)
	docker push $(DOCKERHUB_UID)/$(CONTAINER_NAME):$(VERSION)

run: runDev
