ARG BUILD_FROM="ruby:3.2-slim"
FROM ${BUILD_FROM}

# Needs to be redefined inside the FROM statement to be set for RUN commands
ARG BUILD_FROM

# Install system dependencies including FFmpeg
RUN case "$BUILD_FROM" in \
        *-alpine) \
            # Alpine linux based image \
            apk update && \
            apk add --no-cache \
                build-base \
                ffmpeg \
        ;; \
        *) \
            # Debian based image \
            apt-get update \
            && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
                ffmpeg \
                build-essential \
            && apt-get clean \
            && rm -rf /var/lib/apt/lists/* \
        ;; \
    esac

# Set working directory
WORKDIR /app

# Copy Gemfile and install dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy the rest of the application
COPY . .

# Create directories for audio files and transcripts
RUN mkdir audio transcripts live_audio live_text

# Set environment variables
ENV APP_ENV=production
ENV AUDIO_DIR=/app/live_audio
ENV TRANSCRIPT_DIR=/app/live_text

# Entrypoint and command to run the web application
CMD ["ruby", "app.rb"]
