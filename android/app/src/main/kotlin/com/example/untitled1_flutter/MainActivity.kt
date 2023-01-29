package com.example.untitled1_flutter

import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.media.audiofx.AutomaticGainControl
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity : FlutterActivity() {



  lateinit var audioTrack: AudioTrack

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)


    val am = getSystemService(AUDIO_SERVICE) as AudioManager
    volumeControlStream = AudioManager.STREAM_MUSIC
    am.isSpeakerphoneOn = true

    // Format auf audio is u-law 8KHz it is converted after receiving to PCM to play it
    val intSize = AudioTrack.getMinBufferSize(
      8000,
      AudioFormat.CHANNEL_OUT_MONO,
      AudioFormat.ENCODING_PCM_16BIT
    )

    audioTrack = AudioTrack(
      AudioManager.STREAM_MUSIC,
      8000,
      AudioFormat.CHANNEL_OUT_MONO,
      AudioFormat.ENCODING_PCM_16BIT,
      intSize,
      AudioTrack.MODE_STREAM
    )
    audioTrack.setVolume(1.0f)
    audioTrack.setStereoVolume(AudioTrack.getMaxVolume(), AudioTrack.getMaxVolume())
    enableAndroidAutomaticGainControl(audioTrack)


    val messenger = flutterEngine.dartExecutor.binaryMessenger
    MethodChannel(messenger, "com.kafd.intercom")
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "playAudio" -> {
            playAudio(
              call.argument<List<Int>>("audioBuffer")!!,
            )
          }
          else -> result.notImplemented()
        }
      }
  }


  fun  playAudio(bufferAudio : List<Int>) {
    Log.e("BufferAudio" , bufferAudio.size.toString())
//    var audioShort : ShortArray = shortArrayOf();
//    bufferAudio.map { e->audioShort[bufferAudio.indexOf(e)] = e.toShort() }
    audioTrack.write(bufferAudio.map { e->e.toShort() }.toShortArray(), 0, bufferAudio.size)
    if (audioTrack.playState != AudioTrack.PLAYSTATE_PLAYING) {
      audioTrack.play()
    }
  }


  private fun enableAndroidAutomaticGainControl(audioTrack: AudioTrack) {
    try {
      val agc = AutomaticGainControl.create(audioTrack.audioSessionId)
      if (!agc.enabled) {
        agc.enabled = true
      }
    } catch (throwable: Throwable) {
    }
  }


}




