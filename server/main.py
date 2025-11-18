import azure.cognitiveservices.speech as speechsdk
import time

from pprint import pprint

import difflib
import json

YOUR_SUBCRIPTION_KEY="7XaqOZHg7w8Esgxo3gVsSkvJddZDk6HCCbhSCtptZ3s2y2T0NzUwJQQJ99BKACHYHv6XJ3w3AAAAACOG7U9q"
eastus2="eastus2"



import os
import time
import tempfile
from flask import Flask, request, jsonify
import azure.cognitiveservices.speech as speechsdk

app = Flask(__name__)

@app.route("/assess", methods=["POST"])
def assess_pronunciation():
    # Validate inputs
    if "audio_file" not in request.files:
        return jsonify({"error": "Missing audio_file"}), 400
    if "reference_text" not in request.form:
        return jsonify({"error": "Missing reference_text"}), 400

    audio_file = request.files["audio_file"]
    reference_text = request.form["reference_text"]

    # Save WAV file temporarily
    with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
        audio_path = tmp.name
        audio_file.save(audio_path)

    try:
        # Set up Azure speech config
        speech_config = speechsdk.SpeechConfig(
            subscription=YOUR_SUBCRIPTION_KEY,
            region=eastus2,
        )

        audio_config = speechsdk.audio.AudioConfig(filename=audio_path)

        pronunciation_config = speechsdk.PronunciationAssessmentConfig(
            reference_text=reference_text,
            grading_system=speechsdk.PronunciationAssessmentGradingSystem.HundredMark,
            granularity=speechsdk.PronunciationAssessmentGranularity.Phoneme,
            enable_miscue=True
        )
        pronunciation_config.enable_prosody_assessment()

        language = "en-US"
        speech_recognizer = speechsdk.SpeechRecognizer(
            speech_config=speech_config,
            language=language,
            audio_config=audio_config
        )

        pronunciation_config.apply_to(speech_recognizer)

        result_json_container = {"json": None}
        done = False

        def recognized(evt: speechsdk.SpeechRecognitionEventArgs):
            # evt.result.json contains the full pronunciation assessment information
            result_json_container["json"] = evt.result.json

        def stop_cb(evt):
            nonlocal done
            done = True

        # wire events
        speech_recognizer.recognized.connect(recognized)
        speech_recognizer.session_stopped.connect(stop_cb)
        speech_recognizer.canceled.connect(stop_cb)

        # run continuous recognition
        speech_recognizer.start_continuous_recognition()

        while not done:
            time.sleep(0.5)

        speech_recognizer.stop_continuous_recognition()

        # Return Azure JSON
        if result_json_container["json"] is None:
            return jsonify({"error": "No recognition result returned"}), 500

        return jsonify({"result": json.loads(result_json_container["json"])})

    finally:
        # Clean up temp file
        if os.path.exists(audio_path):
            os.remove(audio_path)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)
