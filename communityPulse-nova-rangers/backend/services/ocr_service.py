import cv2
import pytesseract
from pytesseract import Output
import pdfplumber
import google.generativeai as genai
import os
import tempfile
import base64
import numpy as np
from io import BytesIO

# Configure generative AI with the API key
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

def process_document(file_bytes: bytes, file_type: str) -> dict:
    """
    Main function to process documents and extract text using a multi-step fallback approach:
    1. pdfplumber (for native PDFs)
    2. pytesseract (for images or scanned PDFs with clear text)
    3. gemini (fallback for difficult images)
    """
    try:
        # Step 1: Attempt native PDF extraction
        if file_type.lower() == 'pdf':
            with pdfplumber.open(BytesIO(file_bytes)) as pdf:
                text_pages = []
                for page in pdf.pages:
                    page_text = page.extract_text()
                    if page_text:
                        text_pages.append(page_text)
                extracted_text = "\n".join(text_pages).strip()
                
                # If we got substantial text, return it immediately
                if len(extracted_text) > 50:
                    return {
                        "extracted_text": extracted_text,
                        "ocr_method": "pdfplumber",
                        "confidence": 0.95
                    }

        # Step 2: Computer Vision preprocessing & Tesseract OCR
        # For images and scanned PDFs (where text was too short)
        nparr = np.frombuffer(file_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if img is not None:
            # Preprocessing Pipeline
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            thresh = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 11, 2)
            denoised = cv2.fastNlMeansDenoising(thresh, h=10)
            
            # Run pytesseract
            data = pytesseract.image_to_data(denoised, output_type=Output.DICT, lang='hin+eng')
            
            confidences = []
            texts = []
            
            # Compute mean confidence of entries where conf > 0
            for i in range(len(data['text'])):
                conf = data['conf'][i]
                try:
                    conf_val = float(conf)
                    if conf_val > 0:
                        confidences.append(conf_val)
                        # We use strip on the token text to avoid extraneous whitespace
                        texts.append(data['text'][i])
                except ValueError:
                    continue
                    
            mean_conf = sum(confidences) / len(confidences) if confidences else 0.0
            tesseract_text = " ".join(texts).strip()
            
            # Use tesseract if confidence is sufficient
            if mean_conf >= 75.0:
                return {
                    "extracted_text": tesseract_text,
                    "ocr_method": "tesseract",
                    "confidence": mean_conf
                }
                
        # Step 3: Fallback to Gemini for low-confidence or non-decodable bytes
        base64_img = base64.b64encode(file_bytes).decode('utf-8')
        model = genai.GenerativeModel('gemini-2.5-flash')
        
        response = model.generate_content([
            "Extract all text from this NGO field report image. Return only the extracted text, nothing else.",
            {
                "mime_type": "image/jpeg", 
                "data": base64_img
            }
        ])
        
        return {
            "extracted_text": response.text.strip(),
            "ocr_method": "gemini",
            "confidence": 0.99
        }
        
    except Exception as e:
        # Wrap everything in try/except returning empty extracted_text and error ocr_method
        return {
            "extracted_text": "",
            "ocr_method": "error",
            "confidence": 0.0
        }
