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
# 2. Merge jpg files into pdf
### Usage
```
c:\bin>python merge_jpg_pdf.py jpg
PDF created successfully: jpg\merged_output.pdf

```



# 3. Replace domain name in HAR file
### Usage

## Examples
 
### Single domain
 
```bash
python har_replacer.py \
    -i production.har \
    -o staging.har \
    -old prod.myapp.com \
    -new staging.myapp.com
```
 
### Multiple subdomains via `-replace`
 
```bash
python har_replacer.py \
    -i production.har \
    -o staging.har \
    -replace api.myapp.com     api-staging.myapp.com \
    -replace app.myapp.com     app-staging.myapp.com \
    -replace cdn.myapp.com     cdn-staging.myapp.com \
    -replace auth.myapp.com    auth-staging.myapp.com
```
 
### Using a map file
 
```bash
python har_replacer.py \
    -i production.har \
    -o staging.har \
    --map prod-to-staging.csv
```
 
### Map file plus extra overrides
 
```bash
python har_replacer.py \
    -i production.har \
    -o staging.har \
    --map prod-to-staging.csv \
    -replace payments.thirdparty.com payments.sandbox.com \
    --verbose
```
 
### Compact output (no indentation)
 
```bash
python har_replacer.py \
    -i capture.har \
    -o capture-rewritten.har \
    --map replacements.csv \
    --indent 0
```
 
---
