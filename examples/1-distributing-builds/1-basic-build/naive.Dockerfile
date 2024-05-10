FROM alpine:3.19 AS builder

RUN apk add --no-cache \
  make \
  cmake

RUN apk add --no-cache \
  g++

WORKDIR /src
COPY --link CMakeLists.txt .
COPY --link main.cpp .

RUN CXX=g++ cmake . && make

# this is bad practice, don't distribute your source code

CMD ["./HelloKittyexe"]

