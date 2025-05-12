require './live_transcriber'
<<<<<<< HEAD
stream = "https://rtvelivesrc2.rtve.es/live-origin/24h-hls/bitrate_3.m3u8"

# TODO - Find the last event id the events dirctory and save as the event_id

lt = LiveTranscriber.new(stream, event_id:"rtve")
lt.start
=======
stream = ARGV.shift || 'https://rtvelivesrc2.rtve.es/live-origin/24h-hls/bitrate_3.m3u8'
lt = LiveTranscriber.new stream
lt.start
>>>>>>> 37f43c531e869aa0e20fb7cf2bdb5b1ac7f18eb7
