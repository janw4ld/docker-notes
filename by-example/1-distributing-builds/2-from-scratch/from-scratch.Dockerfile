FROM alpine:3.19 AS builder

RUN apk add --no-cache \
  make \
  cmake

RUN apk add --no-cache \
  g++

WORKDIR /src
COPY --link CMakeLists.txt .
COPY --link main.cpp .

RUN CXX=g++ cmake .
RUN make


FROM scratch

COPY --from=builder /src/HelloKittyexe /app/HelloKittyexe

CMD ["/app/HelloKittyexe"]
