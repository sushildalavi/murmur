FROM golang:1.22 AS build
WORKDIR /src
COPY go.mod ./
COPY cmd ./cmd
RUN go build -o /out/murmurd ./cmd/murmurd

FROM gcr.io/distroless/base-debian12
COPY --from=build /out/murmurd /murmurd
EXPOSE 8080
ENTRYPOINT ["/murmurd"]
