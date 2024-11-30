FROM debian:bullseye AS base

ARG AGAVE_VERSION=stable
ARG RUST_VERSION=stable

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Base OS dependencies
RUN apt update && \
    apt-get install -y bzip2 && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN groupadd --gid 1000 solana && \
    useradd --uid 1000 --gid solana --create-home --shell /bin/bash solana

FROM base AS builder

# Install OS dependencies
RUN apt update && \
    apt-get install -y build-essential clang cmake curl libudev-dev pkg-config protobuf-compiler && \
    rm -rf /var/lib/apt/lists/*

# Switch to the non-root user
USER solana

# Setup Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain $RUST_VERSION -y
ENV PATH="/home/solana/.cargo/bin:${PATH}"

# Get the Agave source
RUN sh -c "$(curl -sSfL https://release.anza.xyz/$AGAVE_VERSION/install)" &&  rm -rf /home/solana/.local/share/solana/install/active_release/bin/perf-libs/

# Create the final image
FROM base AS final

# Copy the binary from the builder image
COPY --from=builder /home/solana/.local /home/solana/.local

ENV PATH="/home/solana/.local/share/solana/install/active_release/bin:$PATH"

# Set ownership for the non-root user
RUN chown -R solana:solana /home/solana

# Switch to the non-root user
USER solana

WORKDIR /home/solana