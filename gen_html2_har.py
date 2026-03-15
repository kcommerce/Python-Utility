import json
import sys
import html
from urllib.parse import urlparse
from datetime import datetime

def get_req_payload(entry):
    post_data = entry['request'].get('postData', {})
    if 'text' in post_data:
        return post_data['text']
    elif 'params' in post_data:
        return json.dumps(post_data['params'], indent=2)
    return "No Payload"

def get_res_payload(entry):
    content = entry['response'].get('content', {})
    text = content.get('text', '')
    if not text:
        return "No Response Body"
    
    formatted_text = text
    if 'application/json' in content.get('mimeType', ''):
        try:
            formatted_text = json.dumps(json.loads(text), indent=2)
        except:
            pass
            
    if len(formatted_text) > 400:
        formatted_text = formatted_text[:200] + "\n\n..........\n\n" + formatted_text[-200:]
        
    return formatted_text

# Note: 'limit' is now set to None by default so it processes the whole file
def generate_html(har_path, output_file, limit=None):
    try:
        with open(har_path, 'r', encoding='utf-8') as f:
            har_data = json.load(f)
    except Exception as e:
        print(f"Error reading HAR file: {e}")
        return

    generation_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    entries = har_data.get('log', {}).get('entries', [])
    
    # Apply limit only if one is explicitly provided
    if limit:
        entries = entries[:limit]
        
    total_requests = len(entries)
    
    hosts = {}
    host_counter = 1
    
    for entry in entries:
        url = entry['request'].get('url', '')
        hostname = urlparse(url).hostname or "Unknown_Host"
        if hostname not in hosts:
            hosts[hostname] = f"S{host_counter}"
            host_counter += 1

    mermaid_code = "sequenceDiagram\n    autonumber\n    participant C as Client\n"
    for hostname, alias in hosts.items():
        mermaid_code += f'    participant {alias} as "{hostname}"\n'

    metadata_storage = {}

    for i, entry in enumerate(entries):
        req = entry['request']
        res = entry['response']
        
        url = req.get('url', '')
        hostname = urlparse(url).hostname or "Unknown_Host"
        server_alias = hosts[hostname]
        
        path = urlparse(url).path or '/'
        short_url = path.split('/')[-1] or '/'
        if len(short_url) > 25: short_url = "..." + short_url[-22:]
        
        safe_short_url = short_url.replace('"', "'")
        method = req.get('method', 'GET')
        status = res.get('status', '200')
        
        mermaid_code += f'    C->>{server_alias}: "{method} {safe_short_url}"\n'
        mermaid_code += f'    {server_alias}-->>C: "{status}"\n'

        req_number = (i * 2) + 1 

        metadata_storage[req_number] = {
            "method": method,
            "url": url,
            "status": status,
            "host": hostname,
            "req_headers": {h['name']: h['value'] for h in req.get('headers', [])},
            "req_payload": get_req_payload(entry),
            "res_headers": {h['name']: h['value'] for h in res.get('headers', [])},
            "res_payload": get_res_payload(entry)
        }

    safe_json = json.dumps(metadata_storage).replace("</", "<\\/")

    html_template = f"""
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>HAR Sequence Explorer</title>
    <script src="https://cdn.jsdelivr.net/npm/mermaid@9.4.3/dist/mermaid.min.js"></script>
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica; display: flex; margin: 0; height: 100vh; overflow: hidden; background: #f0f2f5; }}
        #diagram-container {{ flex: 1; overflow: auto; padding: 20px; }}
        #inspector {{ width: 500px; background: white; border-left: 1px solid #ddd; padding: 20px; overflow-y: auto; box-shadow: -2px 0 5px rgba(0,0,0,0.05); }}
        .mermaid {{ background: white; padding: 20px; padding-bottom: 30vh; border-radius: 8px; min-width: 800px; font-family: monospace; }}
        h3 {{ margin-top: 0; color: #1a73e8; padding-bottom: 10px; border-bottom: 2px solid #1a73e8; }}
        h2 {{ margin-bottom: 5px; }}
        .stats {{ display: flex; align-items: center; gap: 15px; margin-bottom: 15px; }}
        .timestamp {{ font-size: 11px; color: #888; font-style: italic; margin: 0; }}
        .badge {{ background: #1a73e8; color: white; padding: 4px 10px; border-radius: 12px; font-size: 12px; font-weight: bold; }}
        .section-title {{ font-weight: bold; margin-top: 20px; display: block; border-bottom: 1px solid #eee; padding-bottom: 5px; color: #333; }}
        .group-title {{ font-size: 1.1em; color: #d35400; margin-top: 25px; margin-bottom: 5px; font-weight: bold; }}
        .group-title.response {{ color: #27ae60; }}
        pre {{ background: #272822; color: #f8f8f2; padding: 10px; border-radius: 5px; font-size: 12px; white-space: pre-wrap; word-break: break-all; overflow-x: auto; max-height: 400px; overflow-y: auto; margin-top: 5px; }}
        .highlight {{ stroke: #1a73e8 !important; stroke-width: 3px !important; filter: drop-shadow(0 0 5px #1a73e8); cursor: pointer; }}
        .hint {{ font-size: 12px; color: #888; background: #e8f0fe; padding: 10px; border-radius: 5px; border-left: 4px solid #1a73e8; }}
    </style>
</head>
<body>
    <div id="diagram-container">
        <h2>Network Sequence</h2>
        
        <div class="stats">
            <span class="badge">Total Requests: {total_requests}</span>
            <span class="timestamp">Generated on: {generation_time}</span>
        </div>
        
        <p class="hint">Click a <b>Request</b> line (solid arrow) to inspect the full transaction.</p>
        <pre class="mermaid">
{mermaid_code}
        </pre>
    </div>
    <div id="inspector">
        <h3>Transaction Inspector</h3>
        <p id="placeholder" style="color: #666; font-style: italic;">Select a request arrow to view details...</p>
        
        <div id="details" style="display:none;">
            <div class="group-title">📤 Request Details</div>
            <span class="section-title">Method & URL</span>
            <p><strong id="ins-method" style="color:#1a73e8;"></strong> <span id="ins-url" style="font-size: 12px; word-break: break-all;"></span></p>
            <span class="section-title">Request Payload</span>
            <pre id="ins-req-payload"></pre>
            <span class="section-title">Request Headers</span>
            <pre id="ins-req-headers"></pre>

            <div class="group-title response">📥 Corresponding Response</div>
            <span class="section-title">Status</span>
            <p><strong id="ins-status"></strong></p>
            <span class="section-title">Response Payload (Truncated)</span>
            <pre id="ins-res-payload"></pre>
            <span class="section-title">Response Headers</span>
            <pre id="ins-res-headers"></pre>
        </div>
    </div>

    <script>
        const metadata = {safe_json};
        
        // Increased maxTextSize to allow massive HAR files to render without crashing
        mermaid.initialize({{ 
            startOnLoad: true, 
            securityLevel: 'loose',
            maxTextSize: 900000
        }});

        function showDetails(num) {{
            const data = metadata[num];
            if (!data) return; 
            
            document.getElementById('placeholder').style.display = 'none';
            document.getElementById('details').style.display = 'block';
            
            document.getElementById('ins-method').textContent = data.method;
            document.getElementById('ins-url').textContent = data.url;
            document.getElementById('ins-req-payload').textContent = data.req_payload;
            document.getElementById('ins-req-headers').textContent = JSON.stringify(data.req_headers, null, 2);
            
            document.getElementById('ins-status').textContent = data.status;
            document.getElementById('ins-res-payload').textContent = data.res_payload;
            document.getElementById('ins-res-headers').textContent = JSON.stringify(data.res_headers, null, 2);
        }}

        // Adjusted timeout slightly to give massive diagrams extra time to paint before attaching events
        setTimeout(() => {{
            const elements = document.querySelectorAll('.messageText, .sequenceNumber, .messageLine0, .messageLine1');
            
            elements.forEach((el) => {{
                const textContext = el.textContent || "";
                const match = textContext.match(/^\\d+/) || (el.previousElementSibling ? el.previousElementSibling.textContent.match(/^\\d+/) : null);
                const num = match ? match[0] : null;

                if (num && metadata[num]) {{
                    el.addEventListener('mouseenter', () => el.classList.add('highlight'));
                    el.addEventListener('mouseleave', () => el.classList.remove('highlight'));
                    el.addEventListener('click', () => showDetails(num));
                }}
            }});
        }}, 2000); 
    </script>
</body>
</html>
"""
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html_template)
    print(f"Success! Processed {total_requests} requests. File saved to: {output_file}")

if __name__ == "__main__":
    input_har = sys.argv[1] if len(sys.argv) > 1 else 'network.har'
    file_safe_timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    if len(sys.argv) > 2:
        output_html = sys.argv[2]
    else:
        output_html = f"network_explorer_{file_safe_timestamp}.html"
        
    generate_html(input_har, output_html)
