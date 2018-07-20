# Greetings
[![Build Status](https://travis-ci.org/afirth/greetings.svg?branch=master)](https://travis-ci.org/afirth/greetings)
[![GoDoc](https://godoc.org/github.com/afirth/greetings?status.svg)](http://godoc.org/github.com/afirth/greetings)

just some boilerplate

assumes:
 - main()s in `cmd/name/name.go`
 - one package in `./`
 - package import name is the path from `$GOROOT/src/` to here
 - you like `make` (`brew install make` on mac!)

## Quickstart

### go toolchain

```
go get github.com/afirth/greetings && \
cd `go env GOPATH`/src/github.com/afirth/greetings && \
make local-deps && \
make
```

### docker toolchain

N.b. this doesn't make the zip files and shas (`dist/`) for release to github, just the binaries in `bin/`

```
git clone https://github.com/afirth/greetings && \
cd greetings && \
make -f Makefile.docker docker-build && \
make -f Makefile.docker
```

## Usage

 - `make` builds and prepares for distribution
 - `make test` runs go test, coverage, and linters
 - `make watch` runs make test on code changes

 - `make -f Makefile.docker docker-build` builds the docker container
 - `make -f Makefile.docker local-build` builds binaries in container
 - `make -f Makefile.docker local-test` runs tests in container

## TODO
 - mounting directly to gopath would make life much easier - this doesn't work
 - `make -f Makefile.docker local-watch` runs tests on code changes in container
