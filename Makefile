BRANCH_NAME=v1.3.1

build:
	if [ -d "janus-gateway" ]; then \
		echo "Warning: janus-gateway directory already exists. Proceeding..."; \
	else \
		git clone https://github.com/meetecho/janus-gateway.git --branch ${BRANCH_NAME} --depth 1; \
	fi
	$(eval BUILD_DATE=$(shell date -u +'%Y-%m-%dT%H:%M:%SZ'))
	$(eval GIT_BRANCH=$(shell git rev-parse --abbrev-ref HEAD))
	$(eval GIT_COMMIT=$(shell git rev-parse HEAD))
	$(eval VERSION=$(shell git name-rev --tags --name-only $GIT_COMMIT | cut -d"^" -f1 | sed -e 's/^v//g'))
	$(eval DOCKER_IMAGE=janus-gateway)
	echo "BUILD_DATE=${BUILD_DATE} GIT_BRANCH=${GIT_BRANCH} GIT_COMMIT=${GIT_COMMIT} VERSION=${VERSION}"
	docker build -f Dockerfile --no-cache -t ${DOCKER_IMAGE} --build-arg BUILD_DATE=${BUILD_DATE} --build-arg GIT_BRANCH=${GIT_BRANCH} --build-arg GIT_COMMIT=${GIT_COMMIT} --build-arg VERSION=${VERSION} ./janus-gateway
	docker save ${DOCKER_IMAGE} > image.tar

clean:
	rm -fr janus-gateway

rebuild: clean build
