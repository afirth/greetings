VERSION	?= 0.1.0

ORG			?= afirth
VCS			?= github.com

NAME		?= $(shell go list -f '{{.Name}}')

# GOLANG # build options
BINDIR		?= $(CURDIR)/bin/
DISTDIR		?= $(CURDIR)/dist/

#		detect cores or use 1
CORES		:= $(shell getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)
ARCH=$(shell uname -m)
GO			?= go
#TODO add -race once gox supports it
GOFLAGS	:=
LDFLAGS	:= -w -s -X main.Version=$(VERSION)
TAGS		:=
TARGETS	?= linux/amd64 darwin/amd64
TESTS		:= ./...
TESTFLAGS	:= -race

#path of source in a container
CONTAINERSRCDIR := $(shell go env GOPATH | cut -d : -f 1)/src/$(VCS)/$(ORG)/$(NAME)

# MAKE options
MAKEFLAGS += --warn-undefined-variables
.SHELLFLAGS := -eux -o pipefail -c
# Required for globs to work correctly
SHELL=/bin/bash

.PHONY: all build clean compile dist go-deps install
.PHONY: test-integration test-style test-unit
.PHONY: local-deps release watch generate-mocks
.PHONY: link-in-container test-in-container build-in-container 

all: dist test

build: go-deps compile

compile:
	@rm -rf $(BINDIR)
	@gox -parallel=$(CORES) \
		-verbose \
		$(GOFLAGS) \
		-ldflags '$(LDFLAGS)' \
		$(if $(TAGS),-tags '$(TAGS)',) \
		-output "$(BINDIR)/$(NAME)_{{.OS}}_{{.Arch}}/{{.Dir}}" \
		-osarch='$(TARGETS)' \
		./cmd/...
# alpine builds would need CGO_ENABLED=0 and LDFLAGS += -extldflags "-static"


clean:
	@rm -rf $(BINDIR)
	@rm -rf $(DISTDIR)

# go-deps updates the go dependencies to match the latest available in Gopkg.toml
# Gopkg.lock, Gopkg.toml, and vendor/ should then be committed
go-deps:
	dep ensure -v --update

test: test-unit test-coverage test-style 

test-unit:
	$(GO) test $(GOFLAGS) -run $(TESTS) $(TESTFLAGS)

test-style:
	@scripts/validate-go.sh

test-coverage:
	$(GO) test $(TESTFLAGS) -coverprofile=coverage.out $(TESTS)
	$(GO) tool cover -func=coverage.out

dist: build
	$(eval FILES := $(shell ls $(BINDIR)))
	@rm -rf $(DISTDIR) && mkdir $(DISTDIR)
	@for f in $(FILES); do \
		(cd $(BINDIR)/$$f && tar -cvzf $(DISTDIR)/$$f.tar.gz *) && \
		(cd $(DISTDIR) && shasum -a 512 $$f.tar.gz > $$f.sha512); \
	done

#Increment $VERSION in here to use. env GITHUB_TOKEN must be set to a valid API key
release: dist
	@latest_tag=$$(git describe --tags `git rev-list --tags --max-count=1`); \
	comparison="$$latest_tag..HEAD"; \
	if [ -z "$$latest_tag" ]; then comparison=""; fi; \
	changelog=$$(git log $$comparison --oneline --no-merges --reverse); \
	github-release $(ORG)/$(NAME) $(VERSION) "$$(git rev-parse --abbrev-ref HEAD)" "**Changelog**<br/>$$changelog" '$(DISTDIR)/*'; \
	git pull #sync local tags

# links the code into the gopath for compilation
# required for ./vendor to work correctly
# anything _specific_ to codebuild should probably be done in the buildspec
# TODO this could be much much more efficient - link once, accept some args of other targets
link-in-container:
	mkdir -p $(CONTAINERSRCDIR) && rmdir $(CONTAINERSRCDIR)
	cp -Rs $(CURDIR) $(CONTAINERSRCDIR)

build-in-container: GO_LOCK_MD5 = $(shell md5sum Gopkg.lock)
build-in-container: link-in-container
	$(MAKE) -C $(CONTAINERSRCDIR) DISTDIR=$(DISTDIR) BINDIR=$(BINDIR) build
	@test "$(GO_LOCK_MD5)" = "`md5sum Gopkg.lock`" \
		|| (echo "$@ succeeded, but has updated dependencies. Ensure they are committed" && exit 51)

test-in-container: link-in-container
	$(MAKE) -C $(CONTAINERSRCDIR) test

#.git is not copied in the codepipeline source artifact, so use md5sum instead of git to check changes
#https://amzn.to/2JMIpLN
#TODO document this in README
#fail the build if go-deps don't match what's in git
#this is a fatal error in a non-interactive build as it indicates deployed artifacts won't match git
#run make go-deps, commit the changes, and push

local-deps:
	go get -u github.com/c4milo/github-release
	go get -u github.com/mitchellh/gox
	go get -u github.com/golang/dep/cmd/dep
	@which git

watch:
	scantest -command "make test-style test-unit test-coverage"

generate-mocks:
	mockery -dir ../../aws/aws-sdk-go/service/kms/kmsiface --all
	mockery -dir ../../aws/aws-sdk-go/service/dynamodb/dynamodbiface --all
