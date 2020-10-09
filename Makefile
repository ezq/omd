DISTRO=debian

# local builds will be named like this
REPO = local/omd-labs-$(DISTRO)
BRANCH=v2.90
TAG  = v2.90_2
# the final image name
IMAGE=$(REPO):$(TAG)

ifdef SITENAME
	BUILDARGS = --build-arg SITENAME=$(SITENAME)
else
  SITENAME=omd
endif

export DOCKER_REPO=index.docker.io/consol/omd-labs-$(DISTRO)
export IMAGE_NAME=$(IMAGE)
export SOURCE_BRANCH=$(BRANCH)

.PHONY: build bash start echo

build:
  # the hook is also executed on Docker Hub
	./hooks/build $(BUILDARGS)
	@echo "Successfully built" $(IMAGE)
start:
	docker run -p 8443:443 -d $(IMAGE)
bash:
	docker run --rm -p 8443:443 -it $(IMAGE) /bin/bash
