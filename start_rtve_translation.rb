require './live_transcriber'
stream = "https://rtvelivesrc2.rtve.es/live-origin/24h-hls/bitrate_3.m3u8"

# TODO - Find the last event id the events dirctory and save as the event_id

lt = LiveTranscriber.new(stream, event_id:"rtve")
lt.start