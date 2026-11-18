#!/usr/bin/env python3
"""把视频分析结果渲染成 HTML 讲义。

用法：
    python3 build-report.py <content.json> <output.html>
"""
import json, sys, os, html

TEMPLATE_CANDIDATES = [
    os.path.join(os.path.dirname(__file__), '..', 'templates', 'report.html'),
    'templates/report.html',
]

def find_template():
    for p in TEMPLATE_CANDIDATES:
        if os.path.exists(p):
            return open(p, encoding='utf-8').read()
    sys.exit('找不到 templates/report.html')

def render_sections(sections):
    out = []
    for s in sections:
        ts = '<span class="ts">%s</span>' % s['timestamp'] if s.get('timestamp') else ''
        out.append('<h2>%s%s</h2>' % (ts, html.escape(s.get('heading',''))))
        if s.get('body'):
            out.append(s['body'])
        if s.get('evidence'):
            out.append('<div class="evidence">证据：%s</div>' % html.escape(s['evidence']))
    return '\n'.join(out)

def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    data = json.load(open(sys.argv[1], encoding='utf-8'))
    tpl = find_template()

    repl = {
        '{{TITLE}}': html.escape(data.get('title', '未命名视频')),
        '{{DATE}}': data.get('date', ''),
        '{{DURATION}}': data.get('duration', ''),
        '{{PLATFORM}}': data.get('platform', ''),
        '{{SUMMARY}}': html.escape(data.get('summary', '')),
        '{{METHOD}}': html.escape(data.get('method', '')),
        '{{SOURCE_URL}}': html.escape(data.get('source_url', '')),
        '{{CONTENT}}': render_sections(data.get('sections', [])),
    }
    for k, v in repl.items():
        tpl = tpl.replace(k, v)

    open(sys.argv[2], 'w', encoding='utf-8').write(tpl)
    print('OK -> %s' % sys.argv[2])

if __name__ == '__main__':
    main()
