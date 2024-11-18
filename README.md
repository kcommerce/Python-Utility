# Python-Utility
Python Utility 

# 1. Convert Text file to Mp3 (THAI)
### Usage
```
C:\ConvertTxt2Mp3.exe -h
usage: ConvertTxt2Mp3.exe [-h] [--list-voices] [--file FILE] [--voice VOICE] [--output OUTPUT]

Text-to-Speech Converter using Edge-TTS

options:
  -h, --help       show this help message and exit
  --list-voices    List all available Thai voices
  --file FILE      Path to the input text file
  --voice VOICE    Short name of the voice to use (e.g., th-TH-AcharaNeural)
  --output OUTPUT  Path to the output MP3 file
```
### Run
```
C:\ConvertTxt2Mp3.exe --voice th-TH-PremwadeeNeural --file hello.txt --output som.mp3
Converting text to speech using voice: th-TH-PremwadeeNeural
Audio content written to file: som.mp3
```
