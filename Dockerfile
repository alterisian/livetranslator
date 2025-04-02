FROM ruby:3.2-slim

# Install system dependencies including FFmpeg
RUN apt-get update && apt-get install -y \
    ffmpeg \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and install dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy the rest of the application
COPY . .

# Create directories for audio files and transcripts
RUN mkdir -p audio transcripts

# Set environment variables
ENV APP_ENV=production
ENV AUDIO_DIR=/app/audio
ENV TRANSCRIPT_DIR=/app/transcripts

# Command to run the application
CMD ["/bin/sh", "-c" , "ruby app.rb"]

