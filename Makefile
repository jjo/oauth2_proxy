IMG_NAME=xjjo/oauth2_proxy
VERSION=v2.2
IMG_FULL_NAME=$(IMG_NAME):$(VERSION)

build:
	docker build --build-arg SRC_TAG=$(VERSION) -t $(IMG_FULL_NAME) .

# Smoke test oauth2_proxy to start and log listening... banner
test:
	$(eval docker_id=$(shell docker run -d \
	  -e OAUTH2_PROXY_CLIENT_ID=foo \
	  -e OAUTH2_PROXY_CLIENT_SECRET=bar \
	  -e OAUTH2_PROXY_COOKIE_SECRET=Zm9v  \
	  $(IMG_FULL_NAME) \
	  --email-domain=example.com --upstream=http://127.0.0.1:8080/))
	trap 'rc=$$?; docker rm --force $(docker_id); exit $${rc}' 0; \
	  docker logs $(docker_id) 2>&1 | grep 'listening on 127.0.0.1:4180' && echo PASS && exit 0; echo FAIL; exit 1

push:
	docker push $(IMG_FULL_NAME)

clean:
	docker rmi $(IMG_FULL_NAME)
.PHONY: build build test clean
