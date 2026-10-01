import os
import random
from reportlab.lib.pagesizes import letter, A4
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from datetime import datetime, timedelta

styles = getSampleStyleSheet()

def _add_medical_record_header(elements):
    title_style = ParagraphStyle('ModernTitle', parent=styles['Heading1'], textColor=colors.HexColor("#2c3e50"), fontSize=24, alignment=1)
    sub_style = ParagraphStyle('ModernSub', parent=styles['Normal'], textColor=colors.HexColor("#7f8c8d"), alignment=1)
    elements.append(Paragraph("GLOBAL HEALTH & WELLNESS", title_style))
    elements.append(Paragraph("1234 Medical Plaza, Metropolis, NY 10001", sub_style))
    elements.append(Paragraph("Phone: (555) 123-4567 | www.globalhealthcenter.example.com", sub_style))
    elements.append(Spacer(1, 24))

def _add_lab_report_header(elements):
    title_style = ParagraphStyle('LabTitle', parent=styles['Heading1'], textColor=colors.black, fontSize=28, alignment=0)
    sub_style = ParagraphStyle('LabSub', parent=styles['Normal'], textColor=colors.black, alignment=0, fontName='Helvetica-Bold')
    elements.append(Paragraph("NATIONAL DIAGNOSTIC LABORATORIES", title_style))
    elements.append(Paragraph("8800 Science Blvd, Tech Park, CA 90210 | CLIA #: 99D000111", sub_style))
    elements.append(Spacer(1, 20))

def _add_prescription_header(elements):
    title_style = ParagraphStyle('RxTitle', parent=styles['Heading1'], fontName='Times-BoldItalic', fontSize=26, textColor=colors.HexColor("#166534"))
    sub_style = ParagraphStyle('RxSub', parent=styles['Normal'], fontName='Times-Roman', fontSize=12)
    elements.append(Paragraph("Dr. Sarah Wilson, MD, FACP", title_style))
    elements.append(Paragraph("Cardiology & Internal Medicine", sub_style))
    elements.append(Paragraph("Phone: (555) 777-8888 | Fax: (555) 777-8889", sub_style))
    elements.append(Spacer(1, 20))

def _get_pat_table():
    pat_data = [
        ['Patient Name:', 'Johnathan Alexander Doe', 'DOB / Age:', '1982-05-12 / 42 Yrs'],
        ['Gender:', 'Male', 'Blood Type:', 'O Positive'],
        ['Height / Weight:', '178 cm / 75.5 kg', 'BMI:', '23.8'],
        ['Address:', '742 Evergreen Terrace', 'City / Country:', 'Chennai / Tamil Nadu'],
        ['Phone:', '+91 98765 43210', 'Emergency Contact:', '+91 98765 43211 (Wife)']
    ]
    t = Table(pat_data, colWidths=[1.2*inch, 2.5*inch, 1.2*inch, 2.5*inch])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#f8fafc")),
        ('TEXTCOLOR', (0,0), (0,-1), colors.HexColor("#64748b")),
        ('TEXTCOLOR', (2,0), (2,-1), colors.HexColor("#64748b")),
        ('TEXTCOLOR', (1,0), (1,-1), colors.HexColor("#0f172a")),
        ('TEXTCOLOR', (3,0), (3,-1), colors.HexColor("#0f172a")),
        ('FONTNAME', (0,0), (0,-1), 'Helvetica-Bold'),
        ('FONTNAME', (2,0), (2,-1), 'Helvetica-Bold'),
        ('LINEBELOW', (0,0), (-1,-1), 1, colors.HexColor("#e2e8f0")),
        ('PADDING', (0,0), (-1,-1), 8),
    ]))
    return t

def create_comprehensive_medical_record(filename):
    doc = SimpleDocTemplate(filename, pagesize=letter, rightMargin=40, leftMargin=40, topMargin=40, bottomMargin=40)
    elements = []
    
    # PAGE 1
    _add_medical_record_header(elements)
    elements.append(Paragraph("COMPREHENSIVE MEDICAL RECORD", styles['Heading2']))
    elements.append(Spacer(1, 12))
    elements.append(_get_pat_table())
    elements.append(Spacer(1, 20))
    
    subheading_style = ParagraphStyle('MedSub', parent=styles['Heading2'], textColor=colors.HexColor("#3b82f6"))
    normal_style = styles['Normal']
    normal_style.leading = 14
    
    elements.append(Paragraph("1. Chief Complaint & History of Present Illness", subheading_style))
    elements.append(Paragraph("Patient presents today for a comprehensive annual physical examination and follow-up on previously diagnosed Type 2 Diabetes Mellitus and Essential Hypertension. Patient reports feeling generally well but notes occasional mild fatigue in the late afternoons over the past 3 months. No chest pain, shortness of breath, nausea, or vomiting. Patient maintains a moderate exercise routine consisting of brisk walking 3 times a week. Diet consists of moderately healthy meals but admits to occasional high-sugar snacks.", normal_style))
    elements.append(Spacer(1, 15))
    
    elements.append(Paragraph("2. Past Medical History", subheading_style))
    pmh = [
        "• Type 2 Diabetes Mellitus - Diagnosed May 2018.",
        "• Essential Hypertension - Diagnosed November 2020.",
        "• Hyperlipidemia - Diagnosed 2019.",
        "• Appendectomy - March 2010.",
        "• Mild Asthma - Diagnosed 1995 (resolved).",
        "• Seasonal Allergies (Pollen) - Active."
    ]
    for line in pmh:
        elements.append(Paragraph(line, normal_style))
    
    elements.append(PageBreak())
    
    # PAGE 2
    _add_medical_record_header(elements)
    elements.append(Paragraph("3. Review of Systems", subheading_style))
    ros_data = [
        ("General:", "No recent weight loss, fever, or night sweats. Complains of mild afternoon fatigue."),
        ("Cardiovascular:", "No palpitations, orthopnea, or edema. Hypertension well controlled."),
        ("Respiratory:", "No chronic cough, wheezing, or shortness of breath."),
        ("Gastrointestinal:", "Appetite is good. No nausea, vomiting, diarrhea, or constipation. Regular bowel movements."),
        ("Musculoskeletal:", "No joint pain, swelling, or muscle weakness. Full range of motion in all extremities."),
        ("Neurological:", "No headaches, dizziness, numbness, or tingling. Normal gait and coordination."),
        ("Psychiatric:", "No depression, anxiety, or sleep disturbances."),
        ("Dermatological:", "No rashes, suspicious lesions, or changes in pigmentation.")
    ]
    for sys, detail in ros_data:
        elements.append(Paragraph(f"<b>{sys}</b> {detail}", normal_style))
        elements.append(Spacer(1, 10))
        
    elements.append(Paragraph("4. Physical Examination", subheading_style))
    pe_data = [
        "Vitals: BP 122/80 mmHg | HR 72 bpm | Temp 98.6°F | RR 16 breaths/min | SpO2 99% on room air.",
        "General Appearance: Well-developed, well-nourished male in no acute distress.",
        "HEENT: Normocephalic, atraumatic. PERRLA, EOMI. Sclerae anicteric. Tympanic membranes clear bilaterally. Oropharynx clear without erythema or exudate.",
        "Neck: Supple. No thyromegaly, jugular venous distention, or carotid bruits. No lymphadenopathy.",
        "Cardiovascular: Regular rate and rhythm. Normal S1 and S2. No murmurs, rubs, or gallops. Pulses 2+ bilaterally in upper and lower extremities.",
        "Lungs: Clear to auscultation bilaterally. No wheezes, rales, or rhonchi. Symmetrical chest expansion.",
        "Abdomen: Soft, non-tender, non-distended. Bowel sounds active in all four quadrants. No hepatosplenomegaly or masses appreciated.",
        "Extremities: No clubbing, cyanosis, or edema. Calf supple, non-tender.",
        "Skin: Warm and dry. No rashes or suspicious moles. Normal capillary refill.",
        "Neurologic: Alert and oriented x 3. Cranial nerves II-XII intact. Sensation intact to light touch and pinprick globally. Deep tendon reflexes 2+ and symmetric."
    ]
    for detail in pe_data:
        elements.append(Paragraph(f"• {detail}", normal_style))
        elements.append(Spacer(1, 5))
        
    elements.append(PageBreak())
    
    # PAGE 3
    _add_medical_record_header(elements)
    elements.append(Paragraph("5. Assessment", subheading_style))
    elements.append(Paragraph("1. Type 2 Diabetes Mellitus: Currently well-controlled on Metformin. HbA1c is 6.8%, which is near the target range of < 7.0%. Patient advised to continue dietary modifications and increase physical activity to mitigate afternoon fatigue.", normal_style))
    elements.append(Spacer(1, 10))
    elements.append(Paragraph("2. Essential Hypertension: Controlled on Lisinopril 10mg. Blood pressure today is 122/80, which is excellent. Will continue current management.", normal_style))
    elements.append(Spacer(1, 10))
    elements.append(Paragraph("3. Hyperlipidemia: Stable. Patient reports adherence to statin therapy. Lipid panel shows LDL within target range. Will recheck in 6 months.", normal_style))
    
    elements.append(Spacer(1, 20))
    elements.append(Paragraph("6. Plan", subheading_style))
    plan_data = [
        "1. Continue Metformin 500mg BID for diabetes management.",
        "2. Continue Lisinopril 10mg daily for hypertension.",
        "3. Dietary Counseling: Emphasized a low-glycemic, Mediterranean-style diet to stabilize energy levels in the afternoon.",
        "4. Exercise Prescription: Recommended 150 minutes of moderate-intensity aerobic activity per week, plus strength training twice a week.",
        "5. Laboratory Follow-up: Comprehensive Metabolic Panel (CMP), Complete Blood Count (CBC), and Lipid Panel to be drawn in 6 months.",
        "6. Return to Clinic (RTC): Schedule a follow-up appointment in 6 months for a routine check, or sooner if symptoms worsen."
    ]
    for line in plan_data:
        elements.append(Paragraph(line, normal_style))
        elements.append(Spacer(1, 5))
        
    elements.append(Spacer(1, 60))
    elements.append(Paragraph("________________________________________", normal_style))
    elements.append(Paragraph("Electronically signed by Dr. Sarah Wilson, MD", normal_style))
    elements.append(Paragraph(f"Date: {datetime.now().strftime('%B %d, %Y')}", normal_style))
    
    doc.build(elements)


def create_comprehensive_lab_report(filename):
    doc = SimpleDocTemplate(filename, pagesize=A4, rightMargin=30, leftMargin=30, topMargin=30, bottomMargin=30)
    elements = []
    
    def get_lab_header():
        header_data = [
            ['Patient:', 'Johnathan Alexander Doe', 'Gender / Age:', 'Male / 42'],
            ['Blood / BMI:', 'O Positive / 23.8', 'City / Country:', 'Chennai / Tamil Nadu'],
            ['Phone:', '+91 98765 43210', 'Emergency Contact:', '+91 98765 43211'],
            ['Report Date:', '2026-08-16 14:30 PM', 'Accession #:', 'LAB-2026-993847']
        ]
        t = Table(header_data, colWidths=[1.5*inch, 2.3*inch, 1.5*inch, 2.3*inch])
        t.setStyle(TableStyle([
            ('BOX', (0,0), (-1,-1), 2, colors.black),
            ('FONTNAME', (0,0), (0,-1), 'Helvetica-Bold'),
            ('FONTNAME', (2,0), (2,-1), 'Helvetica-Bold'),
            ('PADDING', (0,0), (-1,-1), 4),
        ]))
        return t

    def build_test_table(title, data_rows):
        elements.append(Paragraph(title, ParagraphStyle('t', parent=styles['Heading2'], backColor=colors.black, textColor=colors.white, alignment=1)))
        table_data = [['Test Name', 'Result', 'Flag', 'Units', 'Reference']]
        table_data.extend(data_rows)
        
        tt = Table(table_data, colWidths=[2.5*inch, 1*inch, 0.8*inch, 1*inch, 2.2*inch])
        tt.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,0), colors.lightgrey),
            ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
            ('GRID', (0,0), (-1,-1), 1, colors.black),
            ('PADDING', (0,0), (-1,-1), 4),
            ('ALIGN', (1,0), (3,-1), 'CENTER'),
        ]))
        for i, row in enumerate(data_rows):
            if row[2] == 'HIGH':
                tt.setStyle(TableStyle([('BACKGROUND', (2,i+1), (2,i+1), colors.pink)]))
            elif row[2] == 'LOW':
                tt.setStyle(TableStyle([('BACKGROUND', (2,i+1), (2,i+1), colors.lightblue)]))
        elements.append(tt)
        elements.append(Spacer(1, 15))

    # PAGE 1
    _add_lab_report_header(elements)
    elements.append(get_lab_header())
    elements.append(Spacer(1, 20))
    
    cmp_data = [
        ['Glucose, Fasting', '110', 'HIGH', 'mg/dL', '70 - 99'],
        ['BUN', '15', '', 'mg/dL', '7 - 20'],
        ['Creatinine', '0.9', '', 'mg/dL', '0.6 - 1.2'],
        ['Sodium', '140', '', 'mmol/L', '135 - 145'],
        ['Potassium', '4.2', '', 'mmol/L', '3.5 - 5.1'],
        ['Chloride', '102', '', 'mmol/L', '98 - 107'],
        ['Carbon Dioxide', '26', '', 'mmol/L', '23 - 29'],
        ['Calcium', '9.5', '', 'mg/dL', '8.6 - 10.3'],
        ['Protein, Total', '7.2', '', 'g/dL', '6.0 - 8.3'],
        ['Albumin', '4.5', '', 'g/dL', '3.5 - 5.0'],
    ]
    build_test_table("Comprehensive Metabolic Panel (CMP)", cmp_data)
    
    elements.append(PageBreak())
    
    # PAGE 2
    _add_lab_report_header(elements)
    elements.append(get_lab_header())
    elements.append(Spacer(1, 20))
    
    lipid_data = [
        ['Cholesterol, Total', '180', '', 'mg/dL', '< 200'],
        ['Triglycerides', '145', '', 'mg/dL', '< 150'],
        ['HDL Cholesterol', '45', '', 'mg/dL', '> 40'],
        ['LDL Chol Calc (NIH)', '106', 'HIGH', 'mg/dL', '< 100'],
        ['VLDL Cholesterol Cal', '29', '', 'mg/dL', '5 - 40'],
    ]
    build_test_table("Lipid Panel", lipid_data)
    
    liver_data = [
        ['AST (SGOT)', '22', '', 'IU/L', '0 - 40'],
        ['ALT (SGPT)', '28', '', 'IU/L', '0 - 44'],
        ['Alkaline Phosphatase', '65', '', 'IU/L', '39 - 117'],
        ['Bilirubin, Total', '0.8', '', 'mg/dL', '0.0 - 1.2'],
    ]
    build_test_table("Hepatic Function Panel", liver_data)
    
    elements.append(PageBreak())
    
    # PAGE 3
    _add_lab_report_header(elements)
    elements.append(get_lab_header())
    elements.append(Spacer(1, 20))
    
    thyroid_data = [
        ['TSH', '2.4', '', 'uIU/mL', '0.45 - 4.5'],
        ['Free T4', '1.2', '', 'ng/dL', '0.82 - 1.77'],
        ['Free T3', '3.1', '', 'pg/mL', '2.0 - 4.4'],
    ]
    build_test_table("Thyroid Panel", thyroid_data)
    
    diabetes_data = [
        ['Hemoglobin A1c', '6.8', 'HIGH', '%', '< 5.7'],
        ['Estimated Average Glucose', '148', 'HIGH', 'mg/dL', '< 117'],
    ]
    build_test_table("Diabetes Monitoring", diabetes_data)
    
    elements.append(Spacer(1, 40))
    elements.append(Paragraph("<b>End of Report</b> - Results verified by Dr. Alan Turing, Pathologist", styles['Normal']))
    
    doc.build(elements)


def create_prescription(filename):
    doc = SimpleDocTemplate(filename, pagesize=letter, rightMargin=72, leftMargin=72, topMargin=72, bottomMargin=72)
    elements = []
    
    def add_rx_header():
        _add_prescription_header(elements)
        pat_info = ParagraphStyle('PInfo', fontName='Times-Roman', fontSize=12)
        elements.append(Paragraph(f"<b>Patient Name:</b> Johnathan Alexander Doe (Male, 42 yrs)", pat_info))
        elements.append(Paragraph(f"<b>Blood/BMI:</b> O Positive / 23.8 | <b>Phone:</b> +91 98765 43210", pat_info))
        elements.append(Paragraph(f"<b>City/Country:</b> Chennai / Tamil Nadu | <b>Emergency:</b> +91 98765 43211", pat_info))
        elements.append(Paragraph(f"<b>Date:</b> {datetime.now().strftime('%B %d, %Y')}", pat_info))
        elements.append(Spacer(1, 30))
        
        rx_style = ParagraphStyle('Rx', fontName='Times-BoldItalic', fontSize=48, textColor=colors.black)
        elements.append(Paragraph("Rx", rx_style))
        elements.append(Spacer(1, 20))
    
    med_style = ParagraphStyle('Med', fontName='Courier-Bold', fontSize=11, leading=16)
    instruction_style = ParagraphStyle('Ins', fontName='Times-Roman', fontSize=10, leading=14, textColor=colors.HexColor("#4b5563"))
    
    # PAGE 1
    add_rx_header()
    elements.append(Paragraph("1. Metformin Hydrochloride 500mg ER Tablet", med_style))
    elements.append(Paragraph("Sig: Take one (1) tablet by mouth twice daily with morning and evening meals.", instruction_style))
    elements.append(Paragraph("Indication: Type 2 Diabetes Management.", instruction_style))
    elements.append(Paragraph("Dispense: 60 (Sixty) Tablets | Refills: 3", med_style))
    elements.append(Spacer(1, 30))
    
    elements.append(Paragraph("2. Lisinopril 10mg Tablet", med_style))
    elements.append(Paragraph("Sig: Take one (1) tablet by mouth once daily in the morning.", instruction_style))
    elements.append(Paragraph("Indication: Essential Hypertension.", instruction_style))
    elements.append(Paragraph("Dispense: 30 (Thirty) Tablets | Refills: 3", med_style))
    
    elements.append(PageBreak())
    
    # PAGE 2
    add_rx_header()
    elements.append(Paragraph("3. Atorvastatin 20mg Tablet", med_style))
    elements.append(Paragraph("Sig: Take one (1) tablet by mouth once daily at bedtime.", instruction_style))
    elements.append(Paragraph("Indication: Hyperlipidemia.", instruction_style))
    elements.append(Paragraph("Dispense: 30 (Thirty) Tablets | Refills: 3", med_style))
    elements.append(Spacer(1, 30))
    
    elements.append(Paragraph("4. Vitamin D3 1000 IU Capsule", med_style))
    elements.append(Paragraph("Sig: Take one (1) capsule by mouth once daily.", instruction_style))
    elements.append(Paragraph("Indication: Dietary Supplementation.", instruction_style))
    elements.append(Paragraph("Dispense: 90 (Ninety) Capsules | Refills: 1", med_style))
    
    elements.append(PageBreak())
    
    # PAGE 3
    _add_prescription_header(elements)
    elements.append(Paragraph("Patient Education and Instructions", ParagraphStyle('H', parent=styles['Heading2'])))
    elements.append(Spacer(1, 10))
    
    notes = [
        "<b>Metformin:</b> Take with food to minimize gastrointestinal upset. Do not chew or crush extended-release tablets.",
        "<b>Lisinopril:</b> May cause a dry cough. Report to physician if severe. Avoid potassium supplements unless directed by physician.",
        "<b>Atorvastatin:</b> Best taken in the evening. Avoid large quantities of grapefruit juice. Report any unexplained muscle pain or weakness.",
        "<b>General:</b> Maintain a log of morning fasting blood glucose and home blood pressure readings. Bring this log to the next clinic visit."
    ]
    for note in notes:
        elements.append(Paragraph("• " + note, instruction_style))
        elements.append(Spacer(1, 10))
        
    elements.append(Spacer(1, 60))
    elements.append(Paragraph("________________________________________", ParagraphStyle('SigLine', fontName='Times-Roman', fontSize=12)))
    elements.append(Paragraph("Signature (Dr. Sarah Wilson, MD)               License: NY-987654", ParagraphStyle('Sig', fontName='Times-Roman', fontSize=12)))
    
    doc.build(elements)


def create_blood_report(filename):
    doc = SimpleDocTemplate(filename, pagesize=letter, rightMargin=40, leftMargin=40, topMargin=40, bottomMargin=40)
    elements = []
    
    def get_blood_header():
        title_style = ParagraphStyle('BTitle', parent=styles['Heading1'], textColor=colors.darkred, fontSize=28, alignment=1)
        elements.append(Paragraph("VITA-BLOOD DIAGNOSTICS", title_style))
        elements.append(Spacer(1, 20))
        
        header_data = [
            ['Patient:', 'Johnathan Alexander Doe', 'Gender / Age:', 'Male / 42'],
            ['Blood / BMI:', 'O Positive / 23.8', 'City / Country:', 'Chennai / Tamil Nadu'],
            ['Phone:', '+91 98765 43210', 'Emergency Contact:', '+91 98765 43211'],
            ['ID:', 'BD-558291', 'Date:', '2026-08-16']
        ]
        t_header = Table(header_data, colWidths=[1.5*inch, 2.5*inch, 1.5*inch, 2*inch])
        t_header.setStyle(TableStyle([
            ('TEXTCOLOR', (0,0), (-1,-1), colors.darkred),
            ('FONTNAME', (0,0), (0,-1), 'Helvetica-Bold'),
            ('FONTNAME', (2,0), (2,-1), 'Helvetica-Bold'),
        ]))
        return t_header
        
    def build_blood_table(rows):
        t = Table(rows, colWidths=[2.5*inch, 1.5*inch, 1.5*inch, 2*inch])
        t.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,0), colors.darkred),
            ('TEXTCOLOR', (0,0), (-1,0), colors.whitesmoke),
            ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
            ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.mistyrose, colors.white]),
            ('GRID', (0,0), (-1,-1), 0.5, colors.red),
            ('ALIGN', (1,0), (2,-1), 'CENTER'),
            ('PADDING', (0,0), (-1,-1), 10),
        ]))
        return t

    # PAGE 1
    elements.append(get_blood_header())
    elements.append(Spacer(1, 20))
    elements.append(Paragraph("Complete Blood Count (CBC) with Differential", styles['Heading2']))
    
    cbc_data = [
        ['Parameter', 'Result', 'Status', 'Reference Range'],
        ['White Blood Cells (WBC)', '6.8', 'Normal', '3.8 - 10.8 k/uL'],
        ['Red Blood Cells (RBC)', '4.95', 'Normal', '4.20 - 5.80 M/uL'],
        ['Hemoglobin (HGB)', '15.2', 'Normal', '13.2 - 17.1 g/dL'],
        ['Hematocrit (HCT)', '45.1', 'Normal', '38.5 - 50.0 %'],
        ['MCV', '91.1', 'Normal', '80.0 - 100.0 fL'],
        ['MCH', '30.7', 'Normal', '27.0 - 33.0 pg'],
        ['MCHC', '33.7', 'Normal', '32.0 - 36.0 g/dL'],
        ['RDW', '13.2', 'Normal', '11.0 - 15.0 %'],
        ['Platelets', '245', 'Normal', '140 - 400 k/uL']
    ]
    elements.append(build_blood_table(cbc_data))
    elements.append(PageBreak())
    
    # PAGE 2
    elements.append(get_blood_header())
    elements.append(Spacer(1, 20))
    elements.append(Paragraph("WBC Differential Breakdown", styles['Heading2']))
    
    diff_data = [
        ['Parameter', 'Result (%)', 'Absolute', 'Reference (%)'],
        ['Neutrophils', '60.5', '4.1 k/uL', '40 - 74 %'],
        ['Lymphocytes', '28.2', '1.9 k/uL', '14 - 46 %'],
        ['Monocytes', '8.4', '0.6 k/uL', '4 - 13 %'],
        ['Eosinophils', '2.1', '0.1 k/uL', '0 - 7 %'],
        ['Basophils', '0.8', '0.05 k/uL', '0 - 3 %']
    ]
    elements.append(build_blood_table(diff_data))
    
    elements.append(Spacer(1, 30))
    elements.append(Paragraph("Inflammatory Markers", styles['Heading2']))
    inf_data = [
        ['Parameter', 'Result', 'Status', 'Reference Range'],
        ['C-Reactive Protein (CRP)', '2.4', 'Normal', '< 5.0 mg/L'],
        ['Erythrocyte Sed Rate (ESR)', '12', 'Normal', '< 15 mm/hr']
    ]
    elements.append(build_blood_table(inf_data))
    
    elements.append(PageBreak())
    
    # PAGE 3
    elements.append(get_blood_header())
    elements.append(Spacer(1, 20))
    elements.append(Paragraph("Historical Blood Parameter Comparison", styles['Heading2']))
    
    hist_data = [
        ['Test', 'Today (2026)', 'Last Year (2025)', '2 Years Ago (2024)'],
        ['Hemoglobin', '15.2', '14.9', '15.0'],
        ['WBC Count', '6.8', '7.1', '6.5'],
        ['Platelets', '245', '230', '255'],
        ['CRP', '2.4', '3.1', '2.8']
    ]
    elements.append(build_blood_table(hist_data))
    
    elements.append(Spacer(1, 40))
    elements.append(Paragraph("Clinical Interpretation & Summary", styles['Heading2']))
    notes = [
        "All major blood indices are within standard reference ranges.",
        "The complete blood count shows robust erythropoiesis with optimal hemoglobin levels.",
        "Leukocyte count and differential indicate normal immune function without evidence of acute infection or systemic inflammation.",
        "Inflammatory markers (CRP and ESR) are well within the normal limits.",
        "Historical comparison shows excellent stability in hematological parameters over the past 24 months.",
        "Recommendation: Maintain current healthy lifestyle and dietary habits. Follow up routinely in 12 months."
    ]
    for note in notes:
        elements.append(Paragraph("• " + note, styles['Normal']))
        elements.append(Spacer(1, 5))
        
    doc.build(elements)


if __name__ == "__main__":
    out_dir = "../Sample_Documents"
    os.makedirs(out_dir, exist_ok=True)
    
    create_comprehensive_medical_record(os.path.join(out_dir, "medical_record.pdf"))
    create_comprehensive_lab_report(os.path.join(out_dir, "lab_report.pdf"))
    create_prescription(os.path.join(out_dir, "prescription.pdf"))
    create_blood_report(os.path.join(out_dir, "blood_report.pdf"))
    print("Distinctly styled 3-page PDFs generated.")
