# Daily Deen

Islamic daily routine tracker (Flutter, Android) — Namaz, Quran, Tasbeeh/Azkar, daily mamoolat checklist, streaks and reports. Urdu + English, works fully offline.

Builds run on GitHub Actions (`.github/workflows/build.yml`): analyze → tests → signed APK + AAB (download from the run's *Artifacts*).

Release signing uses `keys/upload-keystore.jks` (alias `upload`) and the `KEYSTORE_PASSWORD` repository secret.
