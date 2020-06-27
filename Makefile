SRCS := $(shell go list ./)
SRC_DIRS := ./
TAGS := "oidc gcp"

EMPTY :=
EQ = $(if $(or $(1),$(2)),$(and $(findstring $(1),$(2)),$(findstring $(2),$(1))),1)

NO_CACHE ?= yes
DOCKER_ARG_NO_CACHE = $(if $(call EQ, $(NO_CACHE), yes), --no-cache, $(EMPTY))
GO_TEST_ARG_NO_CACHE = $(if $(call EQ, $(NO_CACHE), yes), -count=1, $(EMPTY))

PLUGIN_NAME ?= s3
VERSION := 1.4.6
REVISION ?= $(shell git rev-parse --short HEAD --dirty)
REGISTRY ?= docker.io/mattalberts

export GO111MODULE=on

.PHONY: default
default: help;

# Version info for binaries
# GIT_REVISION := $(shell git rev-parse --short HEAD)
# GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
# VPREFIX := github.com/cosmo0920/fluent-bit-go-s3/vendor/github.com/prometheus/common/version
# GO_FLAGS := -ldflags "-X $(VPREFIX).Branch=$(GIT_BRANCH) -X $(VPREFIX).Version=$(VERSION) -X $(VPREFIX).Revision=$(GIT_REVISION)" -tags netgo
# .PHONY: build
# build:
#	go build $(GO_FLAGS) -buildmode=c-shared -o out_s3.so .

.PHONY: build
build:
	@echo building for linux
	GO_EXTLINK_ENABLED=1 CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build \
		-o ./out_s3.so \
		-buildmode=c-shared \
		-ldflags="-s -X main.name=${PLUGIN_NAME} -X main.version=${VERSION} -X main.revision=${REVISION}" \
		-tags netgo -installsuffix netgo \
		-v github.com/cosmo0920/fluent-bit-go-s3

.PHONY: check
check: test vet check-fmt check-static check-ineffassign check-unconvert check-unparam check-error check-spelling

.PHONY: check-error
check-error:
	@echo checking code for unchecked errors
	@go install github.com/kisielk/errcheck
	@errcheck $(SRCS)

.PHONY: check-fmt
check-fmt:
	@echo checking code is formatted
	@test -z "$(shell gofmt -s -l -d -e $(SRC_DIRS) | tee /dev/stderr)"

.PHONY: check-ineffassign
check-ineffassign:
	@echo checking code for ineffectual assignments
	@go install github.com/gordonklaus/ineffassign
	@find $(SRC_DIRS) -name '*.go' | xargs ineffassign

.PHONY: check-spelling
check-spelling:
	@echo checking code and docs for misspellings
	@go install github.com/client9/misspell/cmd/misspell
	@misspell \
		-i clas \
		-locale US \
		-error \
		cmd/* internal/* docs/* pkg/* *.md

.PHONY: check-static
check-static:
	@echo checking code for static issues
	@go install honnef.co/go/tools/cmd/staticcheck
	@staticcheck $(SRCS)

.PHONY: check-unconvert
check-unconvert:
	@echo checking code for unnecessary type conversions
	@go install github.com/mdempsky/unconvert
	@unconvert -v $(SRCS)

.PHONY: check-unparam
check-unparam:
	@echo checking code for unused function parameters and results
	@go install mvdan.cc/unparam
	@unparam ./...

.PHONY: clean
clean:
	@echo cleaning build targets
	@rm -rf bin vendor coverage.txt *.so *.h go.sum
	@go clean -testcache $(SRCS)

.PHONY: coverage
coverage: test
	@echo inspect coverage report
	@go tool cover -func=coverage.txt

.PHONY: deps
deps:
	@echo update dependencies
	@go get -u
	@go mod tidy

.PHONY: no_targets__ help
no_targets__:
help:
	@echo listing available targets
	@sh -c "$(MAKE) -qp no_targets__ | awk -F':' '/^[a-zA-Z0-9][^\$$#\/\\t=]*:([^=]|$$)/{split(\$$1,A,/ /);for(i in A)printf \"> %s\n\", A[i]}' | egrep -v '(__\$$|Makefile)' | sort -u"

.PHONY: race
race:
	@echo installing build targets with race verification
	go install -mod=readonly -v -race -tags $(TAGS) ./...

.PHONY: test
test:
	@echo testing code for issues
	@go test -race $(GO_TEST_ARG_NO_CACHE) \
	-tags $(TAGS) \
	-covermode=atomic \
	-coverprofile=coverage.txt \
	-coverpkg=./... \
	$(SRCS)

.PHONY: unvendor
unvendor:
	@echo unvendoring build targets
	@rm -rf bin vendor

.PHONY: vendor
vendor:
	@echo vendoring dependencies
	@go mod vendor

.PHONY: version
version:
	@echo $(VERSION)

.PHONY: vet
vet: | test
	@echo checking code for suspicious constructs
	@go vet $(SRCS)

.PHONY: container-fluent-bit-go-s3
container-fluent-bit-go-s3: 
	@echo build docker container
	docker build $(DOCKER_ARG_NO_CACHE) \
	--build-arg PLUGIN_NAME=$(PLUGIN_NAME) \
	--build-arg VERSION=$(VERSION) \
	--build-arg REVISION=$(REVISION) \
	-t $(REGISTRY)/fluent-bit:$(VERSION)-$(PLUGIN_NAME)-$(REVISION) -f Dockerfile .

.PHONY: push-fluent-bit-go-s3
push-fluent-bit-go-s3: container-fluent-bit-go-s3
	@echo push docker container
	@docker push $(REGISTRY)/fluent-bit:$(VERSION)-$(PLUGIN_NAME)-$(REVISION)

.PHONY: fluent-bit-go-s3
fluent-bit-go-s3: push-fluent-bit-go-s3 container-fluent-bit-go-s3
