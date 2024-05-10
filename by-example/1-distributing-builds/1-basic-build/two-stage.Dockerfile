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


# we're adding a second FROM directive, to continue building in a new clean env
FROM alpine:3.19

RUN apk add --no-cache \
  libstdc++

COPY --from=builder /src/HelloKittyexe /app/HelloKittyexe

CMD ["/app/HelloKittyexe"]

