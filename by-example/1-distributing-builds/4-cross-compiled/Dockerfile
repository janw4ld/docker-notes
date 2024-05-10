FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx


FROM --platform=$BUILDPLATFORM alpine:3.19 AS builder

RUN apk add --no-cache \
  make \
  cmake

RUN apk add --no-cache \
  clang \
  lld

# "install" the xx tools
COPY --from=xx / /

# magic argument injected by buildkit, and used by xx
ARG TARGETPLATFORM
# install the target platform's `libgcc` and `libc` headers
RUN xx-apk add --no-cache \
  g++

WORKDIR /src
COPY --link CMakeLists.txt .
COPY --link main.cpp .

RUN cmake $(xx-clang++ --print-cmake-defines) .
RUN make && xx-verify ./HelloKittyexe


FROM scratch

COPY --from=builder /src/HelloKittyexe /app/HelloKittyexe

CMD ["/app/HelloKittyexe"]
