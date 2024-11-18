import argparse
import asyncio
import edge_tts

async def list_voices():
    # List available voices
    voices = await edge_tts.list_voices()
    print("Available Thai Voices:")
    for voice in voices:
        if "th-" in voice["Locale"]:
            print(f"{voice['Name']} - {voice['ShortName']} ({voice['Locale']})")

async def text_to_speech(text, output_filename, voice):
    communicate = edge_tts.Communicate(text, voice=voice)
    print(f"Converting text to speech using voice: {voice}")
    await communicate.save(output_filename)
    print(f"Audio content written to file: {output_filename}")

def read_text_from_file(file_path):
    with open(file_path, "r", encoding="utf-8") as file:
        return file.read()

def main():
    parser = argparse.ArgumentParser(description="Text-to-Speech Converter using Edge-TTS")
    parser.add_argument("--list-voices", action="store_true", help="List all available Thai voices")
    parser.add_argument("--file", type=str, help="Path to the input text file")
    parser.add_argument("--voice", type=str, help="Short name of the voice to use (e.g., th-TH-AcharaNeural)")
    parser.add_argument("--output", type=str, default="output.mp3", help="Path to the output MP3 file")

    args = parser.parse_args()

    if args.list_voices:
        asyncio.run(list_voices())
    elif args.file and args.voice:
        text = read_text_from_file(args.file)
        asyncio.run(text_to_speech(text, args.output, args.voice))
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
