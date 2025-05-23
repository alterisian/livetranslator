FROM ruby:3.2-slim

ARG BUNDLER_WITH=development

# Install system dependencies including FFmpeg
RUN apt-get update && apt-get install -y \
    ffmpeg \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

ENV BUNDLER_WITH=${BUNDLER_WITH}

# Copy Gemfile and install dependencies
COPY Gemfile Gemfile.lock ./
RUN if [ "${BUNDLER_WITH}" == "production" ] ; then \
        bundle install --deployment --without development:test ; \
    else \
        bundle install ; \
    fi

# Copy the rest of the application
COPY . .

# Create directories for audio files and transcripts
RUN mkdir -p audio transcripts

# Set environment variables
ENV APP_ENV=production
ENV AUDIO_DIR=/app/live_audio
ENV TRANSCRIPT_DIR=/app/live_text

# Entrypoint and command to run the web application
CMD ["ruby", "app.rb"]
