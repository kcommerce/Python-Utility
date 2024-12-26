from PIL import Image
import os
import sys

def merge_jpg_to_pdf(directory, output_pdf):
    # Get a list of all JPG files in the directory
    jpg_files = [f for f in os.listdir(directory) if f.lower().endswith('.jpg')]
    jpg_files.sort()  # Sort files alphabetically or as needed
    
    if not jpg_files:
        print("No JPG files found in the directory.")
        return

    images = []
    for file in jpg_files:
        img_path = os.path.join(directory, file)
        img = Image.open(img_path)
        # Convert to RGB mode if necessary
        if img.mode != 'RGB':
            img = img.convert('RGB')
        images.append(img)

    # Save images to a single PDF
    output_path = os.path.join(directory, output_pdf)
    images[0].save(output_path, save_all=True, append_images=images[1:])
    print(f"PDF created successfully: {output_path}")

if __name__ == "__main__":
    # Check if the directory is provided as an argument
    if len(sys.argv) < 2:
        print("Usage: python script.py <directory> [output_pdf_name]")
        sys.exit(1)
    
    # Get the directory name from the command-line argument
    directory = sys.argv[1]
    
    # Optional: Specify output PDF name; default to "merged_output.pdf"
    output_pdf = sys.argv[2] if len(sys.argv) > 2 else "merged_output.pdf"
    
    merge_jpg_to_pdf(directory, output_pdf)
