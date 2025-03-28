# Spanish Audio Transcriber

## Setup
```bash
bundle install
```

## Usage
1. Place audio files in the `/audio` directory
2. Receive Spanish transcription and English translation in `/text` directory

## Running the Script (After Setup)
```bash
ruby spanish_transcriber.rb
```

## Dependencies
- Valid `OPENAI_API_KEY` set as an environment variable
- `ffmpeg` installed (required for MP4 to MP3 conversion - not needed if only using MP3/ogg/wav files)

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

