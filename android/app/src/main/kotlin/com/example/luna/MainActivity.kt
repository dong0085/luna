package com.example.luna

import com.ryanheise.audioservice.AudioServiceActivity

// Must extend AudioServiceActivity (not FlutterActivity): audio_service /
// just_audio_background rely on a cached FlutterEngine, and
// JustAudioBackground.init() throws "The Activity class ... is wrong" without it.
class MainActivity : AudioServiceActivity()
