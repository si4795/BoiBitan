import os

def generate_minimal_pdf(output_path="assets/sample_book.pdf"):
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    pages = [
        "Welcome to BoiBitan (BoiBitan e Shagotom)!\n\nThis is Page 1 of the reader.\nEnjoy reading classic Bengali & World Literature.",
        "Chapter 1: The Magic of Reading\n\nPage 2: A room without books is like a body without a soul.\nExplore Shesher Kobita, Devdas, and timeless masterpieces.",
        "Chapter 2: Continuous Reading\n\nPage 3: BoiBitan automatically remembers the last page you read.\nWhen you reopen this book, you will resume right here!",
        "Chapter 3: Offline Freedom\n\nPage 4: With Amarbooks-style Captcha downloads, you can save any PDF\nfor completely offline reading anytime, anywhere.",
        "Epilogue\n\nPage 5: Thank you for reading with BoiBitan!\nHappy Reading & Keep Exploring!"
    ]
    
    # Simple valid PDF 1.4 generator with minimal objects
    objects = []
    
    # 1: Catalog
    # 2: Pages
    # 3..7: Page objects
    # 8: Font
    # 9..13: Content streams
    
    num_pages = len(pages)
    page_obj_ids = [3 + i for i in range(num_pages)]
    font_id = 3 + num_pages
    content_obj_ids = [font_id + 1 + i for i in range(num_pages)]
    
    objects.append(b"<< /Type /Catalog /Pages 2 0 R >>") # 1
    
    kids_str = " ".join([f"{pid} 0 R" for pid in page_obj_ids])
    objects.append(f"<< /Type /Pages /Kids [{kids_str}] /Count {num_pages} >>".encode('ascii')) # 2
    
    for i in range(num_pages):
        cid = content_obj_ids[i]
        page_dict = f"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 {font_id} 0 R >> >> /Contents {cid} 0 R >>"
        objects.append(page_dict.encode('ascii'))
        
    # Font
    objects.append(b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>") # font_id
    
    # Contents
    for i, page_text in enumerate(pages):
        lines = page_text.split("\n")
        stream_content = "BT\n/F1 18 Tf\n50 720 Td\n"
        for idx, line in enumerate(lines):
            safe_line = line.replace("(", "\\(").replace(")", "\\)")
            if idx > 0:
                stream_content += f"0 -28 Td\n({safe_line}) Tj\n"
            else:
                stream_content += f"({safe_line}) Tj\n"
        stream_content += "ET\n"
        stream_bytes = stream_content.encode('latin1')
        content_dict = f"<< /Length {len(stream_bytes)} >>\nstream\n".encode('ascii') + stream_bytes + b"\nendstream"
        objects.append(content_dict)
        
    # Assemble PDF
    pdf = bytearray(b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n")
    offsets = []
    
    for i, obj_data in enumerate(objects):
        offsets.append(len(pdf))
        obj_num = i + 1
        pdf.extend(f"{obj_num} 0 obj\n".encode('ascii'))
        pdf.extend(obj_data)
        pdf.extend(b"\nendobj\n")
        
    startxref = len(pdf)
    pdf.extend(f"xref\n0 {len(objects) + 1}\n0000000000 65535 f \n".encode('ascii'))
    for off in offsets:
        pdf.extend(f"{off:010d} 00000 n \n".encode('ascii'))
        
    pdf.extend(f"trailer\n<< /Size {len(objects) + 1} /Root 1 0 R >>\nstartxref\n{startxref}\n%%EOF\n".encode('ascii'))
    
    with open(output_path, "wb") as f:
        f.write(pdf)
        
    print(f"Sample PDF created at: {output_path} ({len(pdf)} bytes)")

if __name__ == "__main__":
    generate_minimal_pdf()

