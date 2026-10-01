from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors

def create_medical_record_pdf(filename):
    doc = SimpleDocTemplate(filename, pagesize=letter)
    styles = getSampleStyleSheet()
    
    # Custom styles
    title_style = styles['Heading1']
    title_style.alignment = 1  # Center
    heading_style = styles['Heading2']
    normal_style = styles['Normal']
    
    elements = []
    
    # PAGE 1: Demographics and Medical History
    elements.append(Paragraph("Comprehensive Medical Record", title_style))
    elements.append(Spacer(1, 20))
    
    elements.append(Paragraph("1. Patient Demographics", heading_style))
    elements.append(Spacer(1, 10))
    
    demographics_data = [
        ["Field", "Details"],
        ["Name", "Praveen Kumar"],
        ["Age", "22"],
        ["Gender", "Male"],
        ["Phone", "+91 9876543210"],
        ["Emergency Contact", "+91 9123456789"],
        ["Blood Group", "O Positive"],
        ["Blood Type", "O+"],
        ["City", "Chennai"],
        ["Country", "Tamil Nadu"],
        ["Height (cm)", "175.0"],
        ["Weight (kg)", "70.0"],
        ["BMI", "22.86"],
        ["Smoking Status", "Non-smoker"],
        ["Alcohol Use", "Occasional"]
    ]
    
    t1 = Table(demographics_data, colWidths=[150, 300])
    t1.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
        ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
        ('GRID', (0, 0), (-1, -1), 1, colors.black)
    ]))
    elements.append(t1)
    elements.append(Spacer(1, 20))
    
    elements.append(Paragraph("2. Medical History", heading_style))
    elements.append(Spacer(1, 10))
    
    history_data = [
        ["Condition", "Diagnosis Date", "Status", "Severity"],
        ["Asthma", "2010-05-12", "Active", "Mild"],
        ["Hypertension", "2021-08-20", "Managed", "Moderate"]
    ]
    
    t2 = Table(history_data, colWidths=[150, 100, 100, 100])
    t2.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.darkblue),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('GRID', (0, 0), (-1, -1), 1, colors.black)
    ]))
    elements.append(t2)
    elements.append(PageBreak())
    
    # PAGE 2: Medications and Allergies
    elements.append(Paragraph("3. Current Medications", heading_style))
    elements.append(Spacer(1, 10))
    
    medications_data = [
        ["Drug Name", "Dosage", "Frequency", "Route", "Start Date"],
        ["Albuterol Inhaler", "90 mcg", "As needed", "Inhalation", "2020-01-15"],
        ["Lisinopril", "10 mg", "Once daily", "Oral", "2021-08-25"]
    ]
    
    t3 = Table(medications_data, colWidths=[150, 80, 80, 70, 70])
    t3.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.darkgreen),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('GRID', (0, 0), (-1, -1), 1, colors.black)
    ]))
    elements.append(t3)
    elements.append(Spacer(1, 20))
    
    elements.append(Paragraph("4. Allergies", heading_style))
    elements.append(Spacer(1, 10))
    
    allergies_data = [
        ["Allergen", "Severity"],
        ["Penicillin", "High"],
        ["Peanuts", "Moderate"]
    ]
    
    t4 = Table(allergies_data, colWidths=[200, 200])
    t4.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.darkred),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('GRID', (0, 0), (-1, -1), 1, colors.black)
    ]))
    elements.append(t4)
    elements.append(PageBreak())
    
    # PAGE 3: Lab Results and Diagnoses
    elements.append(Paragraph("5. Recent Lab Results", heading_style))
    elements.append(Spacer(1, 10))
    
    labs_data = [
        ["Test Name", "Value", "Unit", "Ref Min", "Ref Max", "Date"],
        ["Hemoglobin A1c", "5.4", "%", "4.0", "5.6", "2023-10-01"],
        ["Cholesterol (Total)", "180", "mg/dL", "125", "200", "2023-10-01"],
        ["Fasting Glucose", "95", "mg/dL", "70", "99", "2023-10-01"]
    ]
    
    t5 = Table(labs_data, colWidths=[120, 50, 50, 60, 60, 80])
    t5.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.purple),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('GRID', (0, 0), (-1, -1), 1, colors.black)
    ]))
    elements.append(t5)
    elements.append(Spacer(1, 20))
    
    elements.append(Paragraph("6. Active Diagnoses", heading_style))
    elements.append(Spacer(1, 10))
    
    diagnoses_data = [
        ["Diagnosis Name", "ICD-10 Code", "Date", "Status", "Severity"],
        ["Essential (primary) hypertension", "I10", "2021-08-20", "Active", "Moderate"],
        ["Mild persistent asthma, uncomplicated", "J45.30", "2010-05-12", "Active", "Mild"]
    ]
    
    t6 = Table(diagnoses_data, colWidths=[150, 80, 80, 70, 70])
    t6.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.teal),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('GRID', (0, 0), (-1, -1), 1, colors.black)
    ]))
    elements.append(t6)
    
    doc.build(elements)
    print(f"Successfully generated {filename}")

if __name__ == '__main__':
    create_medical_record_pdf('../Sample_Documents/Praveen_Kumar_Comprehensive_Medical_Record.pdf')
