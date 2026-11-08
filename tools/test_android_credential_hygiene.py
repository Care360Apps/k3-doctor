#!/usr/bin/env python3
"""Offline regression contract: Android must not persist account passwords.

This is a source-level guard; emulator and backend integration are still needed.
"""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
patient = (root / "lib" / "FirebaseProviders" / "auth_provider.dart").exists()
if patient:
    sign_in = (root / "lib/Screen/Authentication/SignIn.dart").read_text()
    auth = (root / "lib/FirebaseProviders/auth_provider.dart").read_text()
    prefs = (root / "lib/const/preference.dart").read_text()
    assert "setString(FirestoreConstants.password," not in sign_in
    assert "getString(FirestoreConstants.password)" not in auth
    assert "await _preferences.remove(FirestoreConstants.password);" in prefs
    assert "if (key == FirestoreConstants.password)" in prefs
    assert "handleSignIn(emailController.text.toString(), passwordController.text.toString())" in sign_in
else:
    sign_in = (root / "lib/screens/auth/SignIn.dart").read_text()
    auth = (root / "lib/chat/providers/auth_provider.dart").read_text()
    prefs = (root / "lib/constant/preferences.dart").read_text()
    assert "setString(Preferences.password," not in sign_in
    assert "getString(Preferences.password)" not in auth
    assert "await _preferences!.remove(Preferences.password);" in prefs
    assert "if (key == Preferences.password)" in prefs
    # Clinical Firebase identities must be minted by the backend, never
    # registered using the clinician's Laravel account password.
    assert "handleSignIn(email: email.text, password: password.text)" not in sign_in
    assert "createUserWithEmailAndPassword(" not in auth
    assert "signInWithEmailAndPassword(" not in auth
    assert "signInWithCustomToken(" in sign_in
    assert "await FirebaseAuth.instance.signOut();" in prefs

print("PASS: Android password persistence guard is active.")
