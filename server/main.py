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
            region=eastus2
        )

        audio_config = speechsdk.AudioConfig(filename=audio_path)
        pronunciation_config = speechsdk.PronunciationAssessmentConfig(
            reference_text=reference_text,
            grading_system=speechsdk.PronunciationAssessmentGradingSystem.HundredMark,
            granularity=speechsdk.PronunciationAssessmentGranularity.Phoneme,
            enable_miscue=True
        )
        pronunciation_config.enable_prosody_assessment()

        recognizer = speechsdk.SpeechRecognizer(
            speech_config=speech_config,
            audio_config=audio_config
        )

        pronunciation_config.apply_to(recognizer)

        result = recognizer.recognize_once()

        if result.reason != speechsdk.ResultReason.RecognizedSpeech:
            return jsonify({"error": "Could not analyze speech"}), 500
        print("Recognized word: {}".format(result.text))
        return jsonify({"result": json.loads(result.json)})

    finally:
        try:
            os.remove(audio_path)
        except:
            pass

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True)
