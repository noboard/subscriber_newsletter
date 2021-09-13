FROM lukemathwalker/cargo-chef:latest-rust-1.53.0 as chef
WORKDIR /app
FROM chef as planner
COPY . .
# Compute a lock-like file for our project
RUN cargo chef prepare --recipe-path recipe.json

FROM chef as builder
COPY --from=planner /app/recipe.json recipe.json
# Build our project dependencies, not our application!
RUN cargo chef cook --release --recipe-path recipe.json
# Up to this point, if our dependency tree stays the same,
# all layers should be cached.
COPY . .
ENV SQLX_OFFLINE true
# Build our project
RUN cargo build --release --bin subscriber_newsletter
FROM debian:buster-slim AS runtime
WORKDIR /app
RUN apt-get update -y \
&& apt-get install -y --no-install-recommends openssl \
# Clean up
&& apt-get autoremove -y \
&& apt-get clean -y \
&& rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/subscriber_newsletter subscriber_newsletter
COPY configuration configuration
ENV APP_ENVIRONMENT production
ENTRYPOINT ["./subscriber_newsletter"]





# We use the latest Rust stable release as base image
FROM rust:1.53.0 AS builder
# Let's switch our working directory to `app` (equivalent to `cd app`)
# The `app` folder will be created for us by Docker in case it does not
# exist already.
WORKDIR /app
# Copy all files from our working environment to our Docker image
COPY . .
ENV SQLX_OFFLINE true
# Let's build our binary!
# We'll use the release profile to make it faaaast
RUN cargo build --release

FROM debian:buster-slim AS runtime
WORKDIR /app
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends openssl \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
&& rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/subscriber_newsletter subscriber_newsletter
COPY configuration configuration
ENV APP_ENVIRONMENT=production
# When `docker run` is executed, launch the binary!
ENTRYPOINT ["./subscriber_newsletter"]
