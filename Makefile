IMG_NAME=xjjo/oauth2_proxy
VERSION=v2.2
GOARCH=amd64

ifeq ($(GOARCH), arm)
DOCKERFILE_SED_EXPR?=s,FROM alpine:,FROM multiarch/alpine:armhf-v,
IMG_FULL_NAME=$(IMG_NAME):arm-$(VERSION)
else ifeq ($(GOARCH), arm64)
DOCKERFILE_SED_EXPR?=s,FROM alpine:,FROM multiarch/alpine:aarch64-v,
IMG_FULL_NAME=$(IMG_NAME):arm64-$(VERSION)
else
DOCKERFILE_SED_EXPR?=
IMG_FULL_NAME=$(IMG_NAME):$(VERSION)
endif

build: Dockerfile.$(GOARCH).run
	docker build --build-arg SRC_TAG=$(VERSION) --build-arg ARCH=$(GOARCH) -t $(IMG_FULL_NAME) -f $(^) .

Dockerfile.%.run: Dockerfile
	@sed -e "$(DOCKERFILE_SED_EXPR)" Dockerfile > $(@)

# Smoke test oauth2_proxy to start and log listening... banner
test:
	$(eval docker_id=$(shell docker run -d \
	  -e OAUTH2_PROXY_CLIENT_ID=foo \
	  -e OAUTH2_PROXY_CLIENT_SECRET=bar \
	  -e OAUTH2_PROXY_COOKIE_SECRET=Zm9v  \
	  $(IMG_FULL_NAME) \
	  --email-domain=example.com --upstream=http://127.0.0.1:8080/))
	sleep 3
	trap 'rc=$$?; docker rm --force $(docker_id); exit $${rc}' 0; \
	  docker logs $(docker_id) 2>&1 | grep 'listening on 127.0.0.1:4180' && echo PASS && exit 0; echo FAIL; exit 1

push:
	docker push $(IMG_FULL_NAME)

clean:
	docker rmi $(IMG_FULL_NAME)

multiarch-setup:
	docker run --rm --privileged multiarch/qemu-user-static:register
	dpkg -l qemu-user-static

.PHONY: build build test clean multiarch-setup
