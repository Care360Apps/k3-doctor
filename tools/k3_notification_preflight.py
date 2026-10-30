#!/usr/bin/env python3
"""Offline contract checks for K3 mobile chat notification transport."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
provider=(root/'lib/chat/providers/chat_provider.dart').read_text()
errors=[]
for key,ok in {
    'authenticated backend route': 'send_message_to_patient_notification' in provider,
    'notification opt-in defaults off': "'K3_BACKEND_PUSH_ENABLED', defaultValue: false" in provider,
    'no legacy direct FCM HTTP': 'fcm.googleapis.com/fcm/send' not in provider,
    'no FCM server key in client': 'AAAA_' not in provider and 'Enter_Your_Server_Key' not in provider,
    'notification body uses generic chat text': "'New chat message'" in provider and "'New image message'" in provider,
    'no raw chat content in push payload': "'content': content" not in provider,
}.items():
    if not ok: errors.append(key)
wrapper=root/'android/gradle/wrapper/gradle-wrapper.jar'
if not wrapper.exists(): errors.append('Android Gradle wrapper JAR missing')
if not (root/'android/gradlew').exists():errors.append('Android Gradle wrapper launch script missing')
if errors:
    print('K3 notification safety: FAIL')
    for e in errors: print(' - '+e)
    raise SystemExit(1)
print('K3 notification safety: PASS')
