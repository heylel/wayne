.PHONY: run-backend run-worker run-frontend syncdb release

MAKEFLAGS += --warn-undefined-variables

# Build variables
RELEASE_VERSION :=$(shell git describe --always --tags)
UI_BUILD_VERSION :=v1.0.0
SERVER_BUILD_VERSION :=v1.0.0


release: update-version build-release-image push-image

update-version:
	@sed -i "s/__version__/${RELEASE_VERSION}/g" src/backend/main.go
	@sed -i "s/__version__/${RELEASE_VERSION}/g" src/frontend/package.json
	@sed -i "s/__version__/${RELEASE_VERSION}/g" src/backend/controllers/openapi/openapi.go

# run module
run-backend:
	cd src/backend/ && bee run -main=./main.go -runargs="apiserver"

run-worker:
	cd src/backend/ && bee run -main=./main.go -runargs="worker -t AuditWorker -c 2"

run-webhook:
	cd src/backend/ && bee run -main=./main.go -runargs="worker -t WebhookWorker -c 2"

run-frontend:
	cd src/frontend/ && npm start

# dev

syncdb:
	go run src/backend/database/syncdb.go orm syncdb

sqlall:
	go run src/backend/database/syncdb.go orm sqlall > _dev/wayne.sql

initdata:
	go run src/backend/database/generatedata/main.go > _dev/wayne-data.sql

swagger-openapi:
	cd src/backend && swagger generate spec -o openapi.swagger.json

# release, requiring Docker 17.05 or higher on the daemon and client
build-release-image:
	@echo "version: $(RELEASE_VERSION)"
	docker build --no-cache --build-arg RAVEN_DSN=$(RAVEN_DSN) -t 360cloud/wayne:$(RELEASE_VERSION) .

push-image:
	docker push 360cloud/wayne:$(RELEASE_VERSION)


## server builder image
build-server-image:
	cd hack/build/server && docker build --no-cache \
	-t 360cloud/wayne-server-builder:$(SERVER_BUILD_VERSION) .

## ui builder image
build-ui-image:
	docker build -f hack/build/ui/Dockerfile -t 360cloud/wayne-ui-builder:$(UI_BUILD_VERSION) .

