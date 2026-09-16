import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/date_formatter.dart';
import '../providers/history_provider.dart';

class AudioPlayerBottomBar extends StatelessWidget {
  const AudioPlayerBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryProvider>(
      builder: (context, history, child) {
        if (history.currentlyPlayingId == null) {
          return const SizedBox.shrink();
        }

        final playingRecording = history.recordings.firstWhere(
          (r) => r.id == history.currentlyPlayingId,
          orElse: () => history.recordings.first,
        );

        final currentSec = history.currentPosition.inSeconds;
        final totalSec = history.totalDuration.inSeconds > 0
            ? history.totalDuration.inSeconds
            : (playingRecording.durationSeconds > 0 ? playingRecording.durationSeconds : 1);
        final progress = (currentSec / totalSec).clamp(0.0, 1.0);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Track Info & Controls
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreenLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.audiotrack_rounded,
                        color: AppColors.primaryGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playingRecording.contactName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Streaming • ${DateFormatter.formatDuration(currentSec)} / ${DateFormatter.formatDuration(totalSec)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        history.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                        color: AppColors.primaryGreen,
                        size: 38,
                      ),
                      onPressed: () {
                        if (history.isPlaying) {
                          history.pauseAudio();
                        } else {
                          history.resumeAudio();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.iconDefault,
                        size: 22,
                      ),
                      onPressed: () {
                        history.stopAudio();
                      },
                    ),
                  ],
                ),

                // Seeking Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: AppColors.primaryGreen,
                    inactiveTrackColor: AppColors.border,
                    thumbColor: AppColors.primaryGreen,
                  ),
                  child: Slider(
                    value: progress,
                    onChanged: (val) {
                      final seekSeconds = (val * totalSec).toInt();
                      history.seekAudio(Duration(seconds: seekSeconds));
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
