import cv2
import pytesseract
from pytesseract import Output
import pdfplumber
import google.generativeai as genai
import os
import base64
import numpy as np
from io import BytesIO

# Configure generative AI with the API key
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

def _run_tesseract_text(image) -> tuple[str, float]:
    """Run Tesseract with language fallback and return (text, mean_confidence)."""
    last_error = None
    for lang in ("hin+eng", "eng"):
        try:
            data = pytesseract.image_to_data(image, output_type=Output.DICT, lang=lang)
            confidences = []
            texts = []

            for i in range(len(data.get('text', []))):
                conf = data['conf'][i]
                try:
                    conf_val = float(conf)
                    if conf_val > 0:
                        token = (data['text'][i] or "").strip()
                        if token:
                            confidences.append(conf_val)
                            texts.append(token)
                except (ValueError, TypeError):
                    continue

            mean_conf = sum(confidences) / len(confidences) if confidences else 0.0
            return " ".join(texts).strip(), mean_conf
        except Exception as e:
            last_error = e
            continue

    if last_error:
        raise last_error
    return "", 0.0

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

            # Tesseract can fail in some deployments (missing binary/language data).
            # Do not abort OCR; continue to Gemini fallback.
            try:
                tesseract_text, mean_conf = _run_tesseract_text(denoised)
            except Exception:
                tesseract_text, mean_conf = "", 0.0
            
            # Use tesseract only when confidence and extracted content are both strong.
            if mean_conf >= 75.0 and len(tesseract_text) >= 30:
                return {
                    "extracted_text": tesseract_text,
                    "ocr_method": "tesseract",
                    "confidence": mean_conf
                }

            # Keep useful extracted text even with lower confidence instead of hard-failing.
            if len(tesseract_text) >= 30:
                return {
                    "extracted_text": tesseract_text,
                    "ocr_method": "tesseract_low_conf",
                    "confidence": round(mean_conf, 2),
                }

            # Last local fallback: plain OCR on grayscale with no thresholding.
            try:
                plain_text, plain_conf = _run_tesseract_text(gray)
                if len(plain_text) >= 20:
                    return {
                        "extracted_text": plain_text,
                        "ocr_method": "tesseract_plain",
                        "confidence": round(plain_conf, 2),
                    }
            except Exception:
                pass
                
        # Step 3: Fallback to Gemini for low-confidence or non-decodable bytes
        base64_img = base64.b64encode(file_bytes).decode('utf-8')
        model = genai.GenerativeModel('gemini-2.5-flash')
        mime_type = "application/pdf" if file_type.lower() == "pdf" else "image/jpeg"
        
        response = model.generate_content([
            "Extract all text from this NGO field report image. Return only the extracted text, nothing else.",
            {
                "mime_type": mime_type, 
                "data": base64_img
            }
        ])

        gemini_text = (getattr(response, "text", "") or "").strip()
        if not gemini_text:
            return {
                "extracted_text": "",
                "ocr_method": "error",
                "confidence": 0.0
            }

        return {
            "extracted_text": gemini_text,
            "ocr_method": "gemini",
            "confidence": 0.99
        }
        
    except Exception as e:
        # Wrap everything in try/except returning empty extracted_text and error ocr_method
        return {
            "extracted_text": "",
            "ocr_method": f"error:{type(e).__name__}",
            "confidence": 0.0
        }
