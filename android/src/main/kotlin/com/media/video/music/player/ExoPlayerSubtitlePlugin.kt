package com.media.video.music.player

import android.content.Context
import android.util.Log
import androidx.media3.common.C
import androidx.media3.common.Player
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.text.CueGroup
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class ExoPlayerSubtitlePlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private var context: Context? = null
    private var channel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var player: ExoPlayer? = null
    private var trackSelector: DefaultTrackSelector? = null
    private var cueListener: Player.Listener? = null
    private var lastVideoPath: String? = null

    companion object {
        @Volatile
        var instance: ExoPlayerSubtitlePlugin? = null
            private set

        fun ensure(): ExoPlayerSubtitlePlugin =
            instance ?: synchronized(this) {
                instance ?: ExoPlayerSubtitlePlugin().also { instance = it }
            }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel =
            MethodChannel(binding.binaryMessenger, "com.media.video.music.player/subtitles")
        channel!!.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, "com.media.video.music.player/subtitles_events")
        eventChannel!!.setStreamHandler(this)
        instance = this
        Log.d("ExoSubPlugin", "Subtitle plugin attached")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        channel = null
        eventChannel = null
        eventSink = null
        context = null
        instance = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getEmbeddedSubtitles" -> result.success(getEmbeddedSubtitles())
            "selectSubtitle" -> {
                val group = call.argument<Int>("group")
                val track = call.argument<Int>("track")
                if (group != null && track != null) {
                    result.success(selectSubtitle(group, track))
                } else result.error("ARGS", "group & track required", null)
            }
            "disableSubtitles" -> result.success(disableSubtitles())
            else -> result.notImplemented()
        }
    }

    fun setExoPlayer(exo: ExoPlayer, selector: DefaultTrackSelector? = null) {
        this.player = exo
        if (trackSelector == null) {
            trackSelector = selector
            if (trackSelector == null) {
                // Fallback: try to get via reflection if not provided
                try {
                    val field = ExoPlayer::class.java.getDeclaredField("trackSelector")
                    field.isAccessible = true
                    trackSelector = field.get(exo) as? DefaultTrackSelector
                } catch (e: Exception) {
                    Log.e("ExoSubPlugin", "Unable to get TrackSelector: $e")
                }
            }
        }
        // Reattach cue listener
        cueListener?.let { player?.removeListener(it) }
        cueListener = object : Player.Listener {
            override fun onCues(cueGroup: CueGroup) {
                val text = cueGroup.cues.joinToString("\n") { it.text?.toString() ?: "" }
                val event = hashMapOf<String, Any>(
                    "event" to "subtitleCue",
                    "text" to text,
                    "timeUs" to cueGroup.presentationTimeUs
                )
                eventSink?.success(event)
            }
        }
        player?.addListener(cueListener!!)
    }

    fun setVideoPath(path: String?) {
        lastVideoPath = path
    }

    /** Extract embedded subtitles from player.currentTracks */
    fun getEmbeddedSubtitles(): List<Map<String, Any?>> {
        val result = mutableListOf<Map<String, Any?>>()
        val p = player ?: return result

        try {
            val groups = p.currentTracks.groups
            for (i in 0 until groups.size) {
                val group = groups[i]
                if (group.type != C.TRACK_TYPE_TEXT) continue
                val tg = group.mediaTrackGroup
                for (t in 0 until tg.length) {
                    val format = tg.getFormat(t)
                    result.add(
                        mapOf(
                            "groupIndex" to i,
                            "trackIndex" to t,
                            "id" to "${i}_$t",
                            "language" to (format.language ?: "und"),
                            "label" to (format.label ?: "Subtitle"),
                            "mimeType" to format.sampleMimeType,
                            "selected" to group.isTrackSelected(t),
                            "isDefault" to ((format.selectionFlags and C.SELECTION_FLAG_DEFAULT) != 0),
                            "isForced" to ((format.selectionFlags and C.SELECTION_FLAG_FORCED) != 0)
                        )
                    )
                }
            }
        } catch (e: Exception) {
            Log.e("ExoSubPlugin", "Error reading subtitle tracks: $e")
        }

        return result
    }

    /** Select subtitle track */
    fun selectSubtitle(group: Int, track: Int): Boolean {
        val p = player ?: return false
        val selector = trackSelector ?: return false

        try {
            val current = p.currentTracks
            val groups = current.groups
            if (group >= groups.size) return false

            val mediaGroup = groups[group].mediaTrackGroup
            if (track >= mediaGroup.length) return false

            val override = TrackSelectionOverride(mediaGroup, listOf(track))
            val params = selector.buildUponParameters()
                .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, false)
                .clearOverridesOfType(C.TRACK_TYPE_TEXT)
                .addOverride(override)
                .build()

            selector.setParameters(params)
            return true
        } catch (e: Exception) {
            Log.e("ExoSubPlugin", "Select subtitle failed: $e")
            return false
        }
    }

    /** Disable all subtitles */
    fun disableSubtitles(): Boolean {
        val selector = trackSelector ?: return false

        return try {
            val params = selector.buildUponParameters()
                .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, true)
                .build()

            selector.setParameters(params)
            true
        } catch (e: Exception) {
            Log.e("ExoSubPlugin", "Disable subtitles failed: $e")
            false
        }
    }
}
