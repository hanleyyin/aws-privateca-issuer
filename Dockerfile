# Build the manager binary
FROM --platform=${BUILDPLATFORM} golang:1.24 as builder
WORKDIR /workspace

ARG TARGETARCH
ARG TARGETOS

ENV GOPROXY=direct
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum

# Copy the go source
COPY main.go main.go
COPY pkg/ pkg/

ENV CGO_ENABLED=0
ENV GOOS=${TARGETOS:-linux}
ENV GOARCH=${TARGETARCH:-amd64}
ENV GO111MODULE=on
ARG go_cache=/pkg/go-cache
ARG go_mod_cache=/pkg/go-mod

RUN go env -w GOCACHE=${go_cache}
RUN go env -w GOMODCACHE=${go_mod_cache}

# Do an initial compilation before setting the version so that there is less to
# re-compile when the version changes
RUN --mount=type=cache,target=${go_cache} --mount=type=cache,target=${go_mod_cache} go build ./...

ARG pkg_version

ARG user_agent="aws-privateca-issuer"
ENV user_agent=${user_agent}

# Build
RUN --mount=type=cache,target=${go_cache} --mount=type=cache,target=${go_mod_cache} \
    VERSION=$pkg_version && \
    go build \
    -ldflags="-X=github.com/cert-manager/acm-pca-issuer/internal/version.Version=${VERSION} \
    -X github.com/cert-manager/aws-privateca-issuer/pkg/api/injections.PlugInVersion=${VERSION}" \
    -mod=readonly \
    -o manager main.go

# Use distroless as minimal base image to package the manager binary
# Refer to https://github.com/GoogleContainerTools/distroless for more details
FROM --platform=${TARGETPLATFORM:-linux/amd64} gcr.io/distroless/static:nonroot
LABEL org.opencontainers.image.authors="Jochen Ullrich <kontakt@ju-hh.de>"
LABEL org.opencontainers.image.source=https://github.com/cert-manager/aws-privateca-issuer
WORKDIR /
COPY --from=builder /workspace/manager .
USER 65532:65532

ENTRYPOINT ["/manager"]
