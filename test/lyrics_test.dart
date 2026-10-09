import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_ui/models/song_model.dart';
import 'package:mobile_ui/widgets/tech_lyrics_view.dart';

void main() {
  group('Lyrics Parsing & Song Model Tests', () {
    test('Parses LRC content with standard mm:ss.xx format', () {
      const lrc = '''
[00:09.65] The club isn't the best place to find a lover
[00:12.10] So the bar is where I go
[00:14.81] Me and my friends at the table doing shots
''';

      final lines = parseLrcContent(lrc);
      expect(lines.length, 3);
      expect(lines[0].text, "The club isn't the best place to find a lover");
      expect(lines[0].timestamp.inSeconds, 9);
      expect(lines[0].timestamp.inMilliseconds, 9650);

      expect(lines[1].text, "So the bar is where I go");
      expect(lines[1].timestamp.inSeconds, 12);

      expect(lines[2].text, "Me and my friends at the table doing shots");
      expect(lines[2].timestamp.inSeconds, 14);
    });

    test('Song model handles lyrics fields serialization and copyWith', () {
      final json = {
        'id': 'song_123',
        'title': 'Test Song',
        'artist': 'Test Artist',
        'duration': 180,
        'lyrics': 'Plain text lyrics\nLine 2',
        'synced_lyrics': '[00:01.00] Line 1\n[00:05.00] Line 2',
        'lrc_drive_file_id': 'drive_lrc_123',
      };

      final song = Song.fromJson(json);
      expect(song.hasLyrics, isTrue);
      expect(song.hasSyncedLyrics, isTrue);
      expect(song.lyrics, 'Plain text lyrics\nLine 2');
      expect(song.syncedLyrics, '[00:01.00] Line 1\n[00:05.00] Line 2');
      expect(song.lrcDriveFileId, 'drive_lrc_123');

      final serialized = song.toJson();
      expect(serialized['lyrics'], song.lyrics);
      expect(serialized['synced_lyrics'], song.syncedLyrics);
      expect(serialized['lrc_drive_file_id'], song.lrcDriveFileId);

      final updated = song.copyWith(lyrics: 'New lyrics');
      expect(updated.lyrics, 'New lyrics');
      expect(updated.syncedLyrics, song.syncedLyrics);
    });
  });
}
