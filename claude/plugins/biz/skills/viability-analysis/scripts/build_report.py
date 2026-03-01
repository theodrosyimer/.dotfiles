"""
Generate viability analysis phase reports as beautiful PDFs.

Usage:
    python build_report.py <output_path> [--dark|--light] [--phase N] [--project NAME] [--date YYYY-MM-DD]

Default: light mode. Pass --dark for dark mode.
Phase data is read from stdin as JSON or provided via arguments.

When called by the skill, Claude pipes phase findings as JSON.
For template preview, runs with sample data.
"""

import sys
import os
import json
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor, white, Color
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Flowable
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

# ── Register fonts ──
FONT_DIR = '/usr/share/fonts/truetype'
font_map = {
    'Poppins': f'{FONT_DIR}/google-fonts/Poppins-Regular.ttf',
    'Poppins-Bold': f'{FONT_DIR}/google-fonts/Poppins-Bold.ttf',
    'Poppins-Medium': f'{FONT_DIR}/google-fonts/Poppins-Medium.ttf',
    'Poppins-Light': f'{FONT_DIR}/google-fonts/Poppins-Light.ttf',
    'Liberation': f'{FONT_DIR}/liberation/LiberationSans-Regular.ttf',
    'Liberation-Bold': f'{FONT_DIR}/liberation/LiberationSans-Bold.ttf',
}
for name, path in font_map.items():
    if os.path.exists(path):
        pdfmetrics.registerFont(TTFont(name, path))

W, H = A4
MARGIN = 22 * mm
CW = W - 2 * MARGIN

# ── Semantic colors (shared) ──
RED = HexColor('#ef4444')
YELLOW = HexColor('#f59e0b')
GREEN = HexColor('#22c55e')


def get_theme(mode='light', accent='indigo'):
    """Return a complete color theme dict."""

    accents = {
        'indigo': {'primary': '#7c8cf8', 'dark': '#5a6ad4', 'light': '#e8ebff', 'bg': '#f0f2ff'},
        'teal': {'primary': '#2dd4bf', 'dark': '#14b8a6', 'light': '#ccfbf1', 'bg': '#f0fdfa'},
        'navy': {'primary': '#3b82f6', 'dark': '#1e40af', 'light': '#dbeafe', 'bg': '#eff6ff'},
        'coral': {'primary': '#f97316', 'dark': '#ea580c', 'light': '#ffedd5', 'bg': '#fff7ed'},
    }
    a = accents.get(accent, accents['indigo'])

    # WCAG-accessible dark variants (lightened to meet 4.5:1 on #1a1a2e cards)
    dark_accessible = {
        'indigo': '#6b7be5',
        'teal': '#3de5d0',
        'navy': '#5b9bf7',
        'coral': '#ffa04d',
    }

    if mode == 'dark':
        return {
            'page_bg': HexColor('#0f0f1a'),
            'text': HexColor('#e0e0e0'),
            'text2': HexColor('#888899'),
            'heading': HexColor('#ffffff'),
            'card': HexColor('#1a1a2e'),
            'card_alt': HexColor('#16163a'),
            'line': HexColor('#333355'),
            'primary': HexColor(a['primary']),
            'primary_dark': HexColor(dark_accessible.get(accent, a['dark'])),
            'primary_light': HexColor('#2a2a55'),
            'primary_bg': HexColor('#1a1a3e'),
            'quote_bg': HexColor('#1e1e3a'),
            'risk_high_bg': HexColor('#2a1515'),
            'risk_med_bg': HexColor('#2a2515'),
            'risk_low_bg': HexColor('#152a15'),
            'conf_empty': HexColor('#252545'),
            'is_dark': True,
        }
    else:
        # WCAG-accessible light mode colors
        light_accent_on_white = {
            'indigo': '#5d6dd9', 'teal': '#0e8a7e', 'navy': '#1e40af', 'coral': '#c05600',
        }
        light_accent_on_tint = {
            'indigo': '#5161cb', 'teal': '#0c7a70', 'navy': '#1a389e', 'coral': '#a84b00',
        }
        light_accent_on_pale = {
            'indigo': '#5565cf', 'teal': '#0d8276', 'navy': '#1c3ca5', 'coral': '#b45000',
        }
        return {
            'page_bg': white,
            'text': HexColor('#1a1a2e'),
            'text2': HexColor('#6b7280'),
            'heading': HexColor('#111827'),
            'card': HexColor('#f9fafb'),
            'card_alt': HexColor(a['bg']),
            'line': HexColor('#e5e7eb'),
            'primary': HexColor(light_accent_on_white.get(accent, a['primary'])),
            'primary_dark': HexColor(a['dark']),
            'primary_light': HexColor(a['light']),
            'primary_bg': HexColor(a['bg']),
            'quote_bg': HexColor(a['light']),
            'quote_text': HexColor(light_accent_on_tint.get(accent, a['dark'])),
            'next_text': HexColor(light_accent_on_pale.get(accent, a['dark'])),
            'risk_high_bg': HexColor('#fef2f2'),
            'risk_med_bg': HexColor('#fffbeb'),
            'risk_low_bg': HexColor('#f0fdf4'),
            'risk_red': HexColor('#d62b2b'),
            'risk_yellow': HexColor('#b35c00'),
            'risk_green': HexColor('#00861f'),
            'conf_empty': HexColor('#f3f4f6'),
            'is_dark': False,
        }


def build_report(output_path, data, mode='light', accent='indigo'):
    t = get_theme(mode, accent)

    def draw_page(canvas_obj, doc):
        canvas_obj.saveState()
        if t['is_dark']:
            canvas_obj.setFillColor(t['page_bg'])
            canvas_obj.rect(0, 0, W, H, fill=1, stroke=0)
        # Footer
        y = 14 * mm
        canvas_obj.setStrokeColor(t['line'])
        canvas_obj.setLineWidth(0.4)
        canvas_obj.line(MARGIN, y, W - MARGIN, y)
        canvas_obj.setFont('Liberation', 7.5)
        canvas_obj.setFillColor(t['text2'])
        canvas_obj.drawString(MARGIN, y - 9, f"{data['project']} — Viability Analysis")
        canvas_obj.drawCentredString(W / 2, y - 9, f"{doc.page}")
        canvas_obj.drawRightString(W - MARGIN, y - 9, f"Phase {data['phase_num']}: {data['phase_name']}")
        canvas_obj.restoreState()

    doc = SimpleDocTemplate(
        output_path, pagesize=A4,
        leftMargin=MARGIN, rightMargin=MARGIN,
        topMargin=20 * mm, bottomMargin=25 * mm,
    )

    # ── Styles ──
    s_title = ParagraphStyle('title', fontName='Poppins-Bold', fontSize=28, leading=34, textColor=t['heading'], spaceAfter=2 * mm)
    s_sub = ParagraphStyle('sub', fontName='Liberation', fontSize=10, leading=14, textColor=t['text2'], spaceAfter=8 * mm)
    s_h2 = ParagraphStyle('h2', fontName='Poppins-Bold', fontSize=14, leading=18, textColor=t['heading'], spaceBefore=8 * mm, spaceAfter=4 * mm)
    s_body = ParagraphStyle('body', fontName='Liberation', fontSize=9.5, leading=15, textColor=t['text'], alignment=TA_JUSTIFY)
    s_sm = ParagraphStyle('sm', fontName='Liberation', fontSize=8.5, leading=13, textColor=t['text'])
    s_quote = ParagraphStyle('quote', fontName='Liberation', fontSize=10, leading=16, textColor=t.get('quote_text', t['primary_dark'] if not t['is_dark'] else t['primary']), leftIndent=4 * mm)
    s_quote_src = ParagraphStyle('qsrc', fontName='Liberation', fontSize=8, leading=11, textColor=t['text2'], leftIndent=4 * mm)

    story = []

    # ── Phase badge ──
    badge_s = ParagraphStyle('badge', fontName='Poppins-Bold', fontSize=11, leading=14, textColor=white, alignment=TA_CENTER)
    badge = Table([[Paragraph(f'PHASE {data["phase_num"]}', badge_s)]], colWidths=[32 * mm], rowHeights=[8 * mm])
    badge.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (0, 0), t['primary']),
        ('ROUNDEDCORNERS', [4, 4, 4, 4]),
        ('VALIGN', (0, 0), (0, 0), 'MIDDLE'),
        ('LEFTPADDING', (0, 0), (0, 0), 0), ('RIGHTPADDING', (0, 0), (0, 0), 0),
        ('TOPPADDING', (0, 0), (0, 0), 0), ('BOTTOMPADDING', (0, 0), (0, 0), 0),
    ]))
    story.append(badge)
    story.append(Spacer(1, 4 * mm))
    story.append(Paragraph(data['phase_name'], s_title))
    story.append(Paragraph(f"Project: {data['project']}  |  Date: {data['date']}", s_sub))

    # ── Findings Summary ──
    story.append(Paragraph('Findings Summary', s_h2))
    story.append(Paragraph(data.get('summary', ''), s_body))

    # ── Evidence & Sources ──
    if data.get('evidence'):
        story.append(Paragraph('Evidence &amp; Sources', s_h2))
        for src, detail in data['evidence']:
            ev = Table([[
                Paragraph(f'<b>{src}</b>', ParagraphStyle('es', fontName='Liberation-Bold', fontSize=9, textColor=t['primary_dark'] if not t['is_dark'] else t['primary'])),
                Paragraph(detail, s_sm),
            ]], colWidths=[35 * mm, CW - 39 * mm])
            ev.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, -1), t['card']),
                ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                ('TOPPADDING', (0, 0), (-1, -1), 3 * mm), ('BOTTOMPADDING', (0, 0), (-1, -1), 3 * mm),
                ('LEFTPADDING', (0, 0), (-1, -1), 3 * mm),
                ('ROUNDEDCORNERS', [4, 4, 4, 4]),
                ('LINEBELOW', (0, 0), (-1, -1), 0.3, t['primary_light']),
            ]))
            story.append(ev)
            story.append(Spacer(1, 2 * mm))

    # ── Quote callout ──
    if data.get('quote'):
        story.append(Spacer(1, 3 * mm))
        qt = Table([
            [Paragraph(f'<i>"{data["quote"]}"</i>', s_quote)],
            [Paragraph(data.get('quote_source', ''), s_quote_src)],
        ], colWidths=[CW - 6 * mm])
        qt.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), t['quote_bg']),
            ('ROUNDEDCORNERS', [0, 6, 6, 0]),
            ('LEFTPADDING', (0, 0), (-1, -1), 5 * mm),
            ('TOPPADDING', (0, 0), (0, 0), 4 * mm), ('BOTTOMPADDING', (-1, -1), (-1, -1), 3 * mm),
            ('LINEBEFOREDECOR', (0, 0), (0, -1), 3, t['primary']),
        ]))
        story.append(qt)

    # ── Quantitative Data ──
    if data.get('quant_data'):
        story.append(Paragraph('Quantitative Data', s_h2))
        rows = [[
            Paragraph('<b>Metric</b>', ParagraphStyle('qh', fontName='Liberation-Bold', fontSize=8.5, textColor=white)),
            Paragraph('<b>Value</b>', ParagraphStyle('qh2', fontName='Liberation-Bold', fontSize=8.5, textColor=white)),
        ]]
        for m, v in data['quant_data']:
            rows.append([
                Paragraph(m, ParagraphStyle('qm', fontName='Liberation-Bold', fontSize=9, textColor=t['text'])),
                Paragraph(v, s_sm),
            ])
        qt2 = Table(rows, colWidths=[40 * mm, CW - 44 * mm])
        qstyles = [
            ('BACKGROUND', (0, 0), (-1, 0), t['primary_dark']),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('TOPPADDING', (0, 0), (-1, -1), 2.5 * mm), ('BOTTOMPADDING', (0, 0), (-1, -1), 2.5 * mm),
            ('LEFTPADDING', (0, 0), (-1, -1), 3 * mm),
            ('ROUNDEDCORNERS', [4, 4, 4, 4]),
        ]
        for i in range(1, len(rows)):
            bg = t['card'] if i % 2 == 1 else t['card_alt']
            qstyles.append(('BACKGROUND', (0, i), (-1, i), bg))
        qt2.setStyle(TableStyle(qstyles))
        story.append(qt2)

    # ── Risks & Red Flags ──
    if data.get('risks'):
        story.append(Paragraph('Risks &amp; Red Flags', s_h2))
        risk_map = {
            'high': (t.get('risk_red', RED), t['risk_high_bg']),
            'medium': (t.get('risk_yellow', YELLOW), t['risk_med_bg']),
            'low': (t.get('risk_green', GREEN), t['risk_low_bg']),
        }
        for level, desc in data['risks']:
            dot_c, bg = risk_map.get(level, (t['text2'], t['card']))
            rr = Table([[
                Paragraph(f'<font color="{dot_c.hexval()}">&#9679;</font>', ParagraphStyle('d', fontSize=14, alignment=TA_CENTER)),
                Paragraph(f'<b>{level.upper()}</b>', ParagraphStyle('rl', fontName='Liberation-Bold', fontSize=8, textColor=dot_c)),
                Paragraph(desc, s_sm),
            ]], colWidths=[8 * mm, 16 * mm, CW - 28 * mm])
            rr.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, -1), bg),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                ('TOPPADDING', (0, 0), (-1, -1), 2.5 * mm), ('BOTTOMPADDING', (0, 0), (-1, -1), 2.5 * mm),
                ('LEFTPADDING', (0, 0), (0, 0), 2 * mm),
                ('ROUNDEDCORNERS', [4, 4, 4, 4]),
            ]))
            story.append(rr)
            story.append(Spacer(1, 1.5 * mm))

    # ── Confidence Rating ──
    if data.get('confidence'):
        story.append(Paragraph('Confidence Rating', s_h2))
        blocks = [''] * 5
        ct = Table([blocks], colWidths=[18 * mm] * 5, rowHeights=[6 * mm])
        cstyles = [('ROUNDEDCORNERS', [3, 3, 3, 3])]
        for i in range(5):
            c = t['primary'] if i < data['confidence'] else t['conf_empty']
            cstyles.append(('BACKGROUND', (i, 0), (i, 0), c))
            if i < 4:
                cstyles.append(('RIGHTPADDING', (i, 0), (i, 0), 2))
        ct.setStyle(TableStyle(cstyles))
        story.append(ct)
        story.append(Spacer(1, 2 * mm))
        story.append(Paragraph(
            f'<b>{data.get("confidence_label", "")}</b> — {data.get("confidence_text", "")}', s_sm))

    # ── Input for Next Phase ──
    if data.get('next_phase'):
        story.append(Paragraph('Input for Next Phase', s_h2))
        np_color = t.get('next_text', t['primary_dark'] if not t['is_dark'] else t['primary'])
        nt = Table([[Paragraph(data['next_phase'], ParagraphStyle('np', fontName='Liberation', fontSize=9.5, leading=15, textColor=np_color))]],
                   colWidths=[CW - 4 * mm])
        nt.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), t['primary_bg']),
            ('ROUNDEDCORNERS', [6, 6, 6, 6]),
            ('TOPPADDING', (0, 0), (-1, -1), 4 * mm), ('BOTTOMPADDING', (0, 0), (-1, -1), 4 * mm),
            ('LEFTPADDING', (0, 0), (-1, -1), 4 * mm), ('RIGHTPADDING', (0, 0), (-1, -1), 4 * mm),
            ('LINEBEFOREDECOR', (0, 0), (0, -1), 3, t['primary']),
        ]))
        story.append(nt)

    doc.build(story, onFirstPage=draw_page, onLaterPages=draw_page)


# ── Sample data for preview ──
SAMPLE_DATA = {
    'project': 'NutriScan',
    'date': '2026-02-28',
    'phase_num': '1',
    'phase_name': 'Problem Validation',
    'summary': 'Strong evidence of real pain in the nutrition tracking space. Users consistently report frustration with manual meal logging, inaccurate calorie databases, and lack of personalization. Multiple Reddit threads, app store reviews, and health forums confirm daily friction with existing solutions.',
    'evidence': [
        ('Reddit r/nutrition', '2,400+ upvotes on "Why is every calorie counting app terrible?" — users cite manual entry fatigue and inaccurate food databases as top complaints.'),
        ('App Store Reviews', 'MyFitnessPal has 4.6 stars but 23% of recent reviews mention "tedious logging" and "wrong nutritional data" as pain points.'),
        ('Google Trends', '"meal planning app" searches up 34% YoY in France and 28% globally, indicating growing demand.'),
    ],
    'quote': 'I spend 15 minutes every meal trying to log what I ate. By dinner I give up and just guess. There has to be a better way.',
    'quote_source': '— Reddit user, r/loseit (847 upvotes)',
    'quant_data': [
        ('Market size', '$4.8B global nutrition app market (2025)'),
        ('Growth rate', '12.3% CAGR projected through 2030'),
        ('Search volume', '"meal scanner app" — 14,800 monthly searches (EN)'),
        ('Pain signal', '23% of recent MyFitnessPal reviews cite frustration'),
    ],
    'risks': [
        ('high', 'Food databases are notoriously inaccurate — building a reliable one is expensive'),
        ('medium', 'Health app regulations vary by country and could slow international expansion'),
        ('low', 'AI-based food recognition accuracy may not meet user expectations initially'),
    ],
    'confidence': 4,
    'confidence_label': 'High',
    'confidence_text': 'Multiple independent sources confirm pain. Users actively complain and pay for imperfect solutions. Market is growing.',
    'next_phase': 'Phase 2 should focus on identifying which specific persona (fitness enthusiasts, dieters, health-condition managers) feels this pain most acutely and has the highest willingness to pay.',
}


if __name__ == '__main__':
    args = sys.argv[1:]

    if not args:
        print("Usage: python build_report.py <output_path> [--dark|--light] [--accent indigo|teal|navy|coral]")
        print("Running preview with sample data...")
        out_dir = '/mnt/user-data/outputs/pdf-samples'
        os.makedirs(out_dir, exist_ok=True)
        build_report(f'{out_dir}/preview_dark.pdf', SAMPLE_DATA, mode='dark')
        build_report(f'{out_dir}/preview_light.pdf', SAMPLE_DATA, mode='light')
        print(f'Created: {out_dir}/preview_dark.pdf')
        print(f'Created: {out_dir}/preview_light.pdf')
        sys.exit(0)

    output_path = args[0]
    mode = 'light'
    accent = 'indigo'

    for a in args[1:]:
        if a == '--dark':
            mode = 'dark'
        elif a == '--light':
            mode = 'light'
        elif a.startswith('--accent'):
            idx = args.index(a)
            if idx + 1 < len(args):
                accent = args[idx + 1]

    # Try reading JSON from stdin
    if not sys.stdin.isatty():
        data = json.load(sys.stdin)
    else:
        data = SAMPLE_DATA

    build_report(output_path, data, mode=mode, accent=accent)
    print(f'Created: {output_path}')
