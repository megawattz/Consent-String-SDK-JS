PRODUCT=gdpr_lua
ROLE_DEFAULT=dev  # version above normal
ROLE := $(ROLE_DEFAULT)
DOCKERFILE = Dockerfile.$(ROLE)
IMAGE_NAME = $(PRODUCT)_$(ROLE)
PERSISTENT_ROOT = /d1/apps/$(PRODUCT)/
PERSISTENT_DATA_DIR = var
PERSISTENT_LOG_DIR = log
PERSISTENT_CONFIG_DIR = etc
PERSISTENT_BIN_DIR = bin
VOLUMES = \
	-v $(CURDIR):/source \
	-v $(CURDIR)/$(PERSISTENT_DATA_DIR):$(PERSISTENT_ROOT)/$(PERSISTENT_DATA_DIR) \
	-v $(CURDIR)/$(PERSISTENT_LOG_DIR):$(PERSISTENT_ROOT)/$(PERSISTENT_LOG_DIR) \
	-v $(CURDIR)/$(PERSISTENT_CONFIG_DIR):$(PERSISTENT_ROOT)/$(PERSISTENT_CONFIG_DIR) \
	-v $(CURDIR)/$(PERSISTENT_BIN_DIR):$(PERSISTENT_ROOT)/$(PERSISTENT_BIN_DIR)
HOSTARG = -h $(shell hostname)
HOME = $(shell pwd)

.PHONY: build rebuild run restart bash stop clean setup

help:
	@echo "Please use 'make <target> ROLE=<ROLE> if you don't specify role, the default will be \"$(ROLE)\" and will use Dockerfile.$(ROLE)"
	@echo "where <target> is one of"
	@echo "Please use 'make <target> ROLE=<role>' where <target> is one of"
	@echo "  dbuild	    build the docker image containing a redis cluster"
	@echo "  drebuild	  rebuilds the image from scratch without using any cached layers"
	@echo "  drun	      run the built docker image"
	@echo "  drestart	  restarts the docker image"
	@echo "  dbash	     starts bash inside a running container."
	@echo "  dclean	    removes the tmp cid file on disk"
	@echo 'equivalent commands may exist for docker compose container but they start with "c" like "make cbash"'
	@echo -n "and <ROLE> is a suffix of a Dockerfile in this directory, one of these: "
	@ls Dockerfile.*
	@echo "Example: make ROLE=dev drun"

build:
	@echo "Building docker image..."
	docker build -f ${DOCKERFILE} -t ${IMAGE_NAME} .

rebuild:
	@echo "Rebuilding docker image using: "
	docker build --rm=true -f ${DOCKERFILE} --no-cache=true -t ${IMAGE_NAME} .

setup:	# not used for every application
	mkdir -p $(PERSISTENT_DATA_DIR)
	mkdir -p $(PERSISTENT_LOG_DIR)
	mkdir -p $(PERSISTENT_CONFIG_DIR)
	mkdir -p $(PERSISTENT_BIN_DIR)

run:	setup
	@echo "Running docker image..."  # you must stop and rm any container of the same name docker run will fail
	@echo "HOSTARG: $(HOSTARG)"
	docker run --rm $(VOLUMES) $(PORTS) $(HOSTS) $(HOSTARG) -it --name $(IMAGE_NAME) $(IMAGE_NAME) $(CMD)

restart: stop
	-docker rm ${IMAGE_NAME} 2>/dev/null
	mkdir -p $(PERSISTENT_DATA_DIR)
	mkdir -p $(PERSISTENT_LOG_DIR)
	mkdir -p $(PERSISTENT_CONFIG_DIR)
	mkdir -p $(PERSISTENT_BIN_DIR)
	docker run --rm $(VOLUMES) $(PORTS) $(HOSTS) $(HOSTARG) -it --name ${IMAGE_NAME} ${IMAGE_NAME} $(CMD)

shell:
	docker run $(VOLUMES) $(PORTS) $(HOSTS) -i -t ${IMAGE_NAME} /bin/bash

bash:
	docker exec -it ${IMAGE_NAME} /bin/bash

stop:
	-@docker stop ${IMAGE_NAME}

clean:
	 # Cleanup cidfile on disk
	 -rm $(CID_FILE) 2>/dev/null
