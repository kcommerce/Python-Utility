import fitz  # PyMuPDF
import sys

def reduce_pdf(input_path, output_path):
    input_pdf = fitz.open(input_path)
    
    # Create a new PDF to save the reduced size version
    output_pdf = fitz.open()
    
    for page_num in range(input_pdf.page_count):
        page = input_pdf.load_page(page_num)
        output_pdf.insert_pdf(input_pdf, from_page=page_num, to_page=page_num)
    
    # Save the reduced PDF
    output_pdf.save(output_path, deflate=True)
    print(f"Reduced PDF saved as: {output_path}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python reduce_pdf.py <input_pdf>")
        sys.exit(1)
    
    input_pdf = sys.argv[1]
    output_pdf = input_pdf.replace(".pdf", ".compress.pdf")
    
    reduce_pdf(input_pdf, output_pdf)