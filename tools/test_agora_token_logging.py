from pathlib import Path

source = Path('lib/screens/videoCall/video_Call.dart').read_text(encoding='utf-8')
for unsafe in ('Tocken : ', 'Token : ', 'Channel Name: '):
    assert unsafe not in source, f'RTC credential diagnostic leaked: {unsafe}'
assert 'AgoraVideoView(' in source
print('PASS RTC token and channel debugging is disabled')
