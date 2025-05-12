# Spanish Audio Transcriber

## Configuration

No matter which environment you will need to setup your Open AI API Key.

Create a .env file in the project root directory with the following:
```
OPENAI_API_KEY=<paste your own api key here>
STREAM_KEY_NAME=hello
```

Or, export as environment variable.
i.e. in your terminal:

```
export OPENAI_API_KEY=<paste your own api key here>
export STREAM_KEY_NAME=hello
```

## Quick Proof Of Concept Setup

See the rtve live stream, translated, and displayed in a web browser.

Bring up the development stack by issuing the docker compose command:

`docker compose up`

This will allow you to view the translations live at:
http://localhost:4567 

Either point a local broadcast tool (for example [OBS Studio](https://obsproject.com/) at the endpoint: `rtmp://localhost:1935/stream` and set the stream key name.

Or, use ffmpeg to pull and direct an example stream (RTVe here) to livetranslation RTMP endpoint:

`ffmpeg -analyzeduration 0 -i 'https://rtvelivesrc2.rtve.es/live-origin/24h-hls/bitrate_3.m3u8' -f flv rtmp://localhost:1935/stream/hello`

Dependencies: 
- Docker (https://www.docker.com/get-started/)
- Open AI API Key [https://platform.openai.com/docs/guides/speech-to-text](https://platform.openai.com/api-keys)

## How To Run In Codespaces

GitHub allows you to develop in a web-based IDE, that looks like VSCode.
From github repo, select the code dropdown, and codespaces. You can then create a new codespace from there.
The codespace allows you to develop in the cloud with other humans.

## Run The Application Manually

## Setup
```bash
bundle install
```

## Usage
1. Start the sinatra web server with:
bundle exec ruby app.rb
2. Start the demo stream with this script:
bundle exec ruby start_rtve_translation.rb
3. Open a web browser at the following address:
http://localhost:4567

## Dependencies
- Valid `OPENAI_API_KEY` set as an environment variable
- `ffmpeg` installed (required for MP4 to MP3 conversion - not needed if only using MP3/ogg/wav files)

# Transcribing Static Audio

1. Place audio files in the `/audio` directory
2. Receive Spanish transcription and English translation in `/text` directory

## Running the static translator
```bash
ruby spanish_transcriber.rb
```

## OBS Configuration
- Stream Type: Custom Streaming Server
- URL: `rtmp://localhost:1935/stream`
- Stream Key: `<stream key name>`

## Features
- Processes MP3, OGG, and MP4 files
- Converts MP4 to MP3 using ffmpeg (with error handling)
- Transcribes audio and translates it to English (default)
- Supports batch processing with configurable project name
- Ensures already processed files are skipped
- Includes logging for debugging

## Troubleshooting

### Check OpenAI API Key
```bash
curl https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
     "model": "gpt-4",
     "messages": [{"role": "user", "content": "Say this is a test!"}],
     "temperature": 0.7
   }'
```

### Check Transcription
```bash
curl --request POST \
  --url https://api.openai.com/v1/audio/transcriptions \
  --header "Authorization: Bearer $OPENAI_API_KEY" \
  --header 'Content-Type: multipart/form-data' \
  --form file=@./audio/amelia.mp3 \
  --form model=whisper-1
```

## Application Deployment 

### Heroku Deployment

Deploying A Simple Sinatra Helloworld to Heroku

Gemfile needs a ruby version:

ruby '3.2.2' # Other options: 3.2.8 (Heroku, 3.2.x latest), 3.3.7

Gemfile also needs:

gem 'rackup' # added for heroku error
gem 'puma' # added for heroku error
gem 'sinatra'

Heroku will need to have a Gemfile.lock, so ensure that is committed, after running:

bundle install

A Procfile should exist to run on heroku - it should run the sinatra app:

   web: ruby app.rb -o 0.0.0.0 -p $PORT

A config.ru file should exist referencing the same app file:

require './app'
run Sinatra::Application


Creating The Heroku Instance

heroku create boquercom

You now need to go into the Heroku Dashboard, and allow the server to run via the dashboard. This is PAID feature. So, you may want to also STOP the server via the dashboard later.

Pushing The Latest Code To Heroku

Do your changes. Commit with message, and push to your own (feature) branch. 
i.e. git commit -am "description of changes"

Automating The Deployment

It is possible to run the rspec tests either via Github or Heroku, and then deploy. 

## Trying Alternative Hosts.

- Fly.io should be free, but was having issues before I tried Heroku. Probably worth retrying.

- Obtaining a AWS mini free instance (Believe free for a year for new customers like Boquercom?) Think, with Docker finished, and a motivated maintainer this should be possible.

