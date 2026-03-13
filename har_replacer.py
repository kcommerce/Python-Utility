#!/usr/bin/env python3
"""
HAR Domain Replacer
====================
Reads a HAR file, replaces old domain with new domain throughout:
  - URLs (request/response)
  - Request/response headers (Host, Location, Referer, Origin, Cookie, Set-Cookie, etc.)
  - Request POST data (body, params, text)
  - Response content (text, base64-decoded JSON/text bodies)
  - Recalculates Content-Length, Content-MD5, and updates Cookies/headers accordingly

Usage:
    python har_replacer.py -i input.har -o output.har -old example.com -new newdomain.com
    python har_replacer.py -i input.har -o output.har -old example.com -new newdomain.com --verbose
"""

import json
import re
import base64
import hashlib
import argparse
import sys
import copy
from urllib.parse import urlparse, urlunparse, parse_qsl, urlencode, quote, unquote
from typing import Any

# ─── Colour helpers ────────────────────────────────────────────────────────────
GREEN  = "\033[92m"
YELLOW = "\033[93m"
CYAN   = "\033[96m"
RED    = "\033[91m"
RESET  = "\033[0m"
BOLD   = "\033[1m"

def log(msg, colour=RESET):    print(f"{colour}{msg}{RESET}")
def info(msg):                 log(f"  [INFO]  {msg}", CYAN)
def changed(msg):              log(f"  [CHG]   {msg}", GREEN)
def warn(msg):                 log(f"  [WARN]  {msg}", YELLOW)
def error(msg):                log(f"  [ERR]   {msg}", RED)


# ─── Core string replacement ────────────────────────────────────────────────────

def replace_domain_in_string(text: str, old: str, new: str) -> tuple[str, int]:
    """
    Case-insensitive replacement of old domain with new domain.
    Handles plain text, URL-encoded, and JSON-escaped variants.
    Returns (new_text, count_of_replacements).
    """
    if not text or old.lower() not in text.lower():
        return text, 0

    count = 0

    # 1. Plain replacement (case-insensitive)
    pattern = re.compile(re.escape(old), re.IGNORECASE)
    new_text, n = pattern.subn(new, text)
    count += n

    # 2. URL-encoded variant: e.g. example%2Ecom or example%2ecom
    old_urlenc = quote(old, safe='')
    new_urlenc = quote(new, safe='')
    if old_urlenc.lower() != old.lower() and old_urlenc.lower() in new_text.lower():
        pattern2 = re.compile(re.escape(old_urlenc), re.IGNORECASE)
        new_text, n2 = pattern2.subn(new_urlenc, new_text)
        count += n2

    # 3. JSON unicode-escaped variant: e.g. \u0065xample.com (rare but possible)
    old_json_escaped = old.encode('unicode_escape').decode('ascii')
    if old_json_escaped != old and old_json_escaped.lower() in new_text.lower():
        pattern3 = re.compile(re.escape(old_json_escaped), re.IGNORECASE)
        new_text, n3 = pattern3.subn(new, new_text)
        count += n3

    return new_text, count


# ─── URL manipulation ───────────────────────────────────────────────────────────

def replace_in_url(url: str, old: str, new: str) -> tuple[str, int]:
    """
    Replace domain in a URL, handling all components correctly.

    Handles:
      - Full URLs:          https://example.com/path
      - Scheme-less URLs:   //example.com/path
      - Host-only:          example.com
      - Host + port:        example.com:8080   (urlparse mis-parses these — handled manually)
      - With credentials:   user:pass@example.com
    """
    if not url:
        return url, 0

    # ── Detect scheme-less host(:port) strings ──────────────────────────────
    # urlparse("example.com:8080") wrongly puts "example.com" in scheme and
    # "8080" in path.  Detect this early and handle manually.
    parsed = urlparse(url)
    if parsed.scheme and not parsed.netloc:
        # Looks like urlparse mis-parsed a bare "host" or "host:port" string.
        # Re-parse by prepending a dummy scheme so netloc is populated.
        parsed2 = urlparse("http://" + url)
        if parsed2.netloc:
            # Replace only in the netloc (host+port) portion
            netloc2 = parsed2.netloc
            new_netloc2, n = replace_domain_in_string(netloc2, old, new)
            if n:
                return url.replace(netloc2, new_netloc2, 1), n
            return url, 0

    count  = 0
    netloc = parsed.netloc

    # ── Handle user:pass@host:port in netloc ─────────────────────────────────
    if '@' in netloc:
        userinfo, hostpart = netloc.rsplit('@', 1)
    else:
        userinfo, hostpart = None, netloc

    # Strip port (IPv6 literals like [::1]:8080 are safe — rsplit from right)
    if ':' in hostpart and not hostpart.startswith('['):
        host, port = hostpart.rsplit(':', 1)
        # Validate port is numeric; if not, treat the whole thing as the host
        if not port.isdigit():
            host, port = hostpart, None
    else:
        host, port = hostpart, None

    # Replace in host
    new_host, n = replace_domain_in_string(host, old, new)
    count += n

    # Rebuild netloc
    new_hostpart = f"{new_host}:{port}" if port else new_host
    new_netloc   = f"{userinfo}@{new_hostpart}" if userinfo else new_hostpart

    # Replace in path, query, fragment
    new_path,     np = replace_domain_in_string(parsed.path,     old, new)
    new_query,    nq = replace_domain_in_string(parsed.query,    old, new)
    new_fragment, nf = replace_domain_in_string(parsed.fragment, old, new)
    count += np + nq + nf

    new_url = urlunparse((parsed.scheme, new_netloc, new_path, parsed.params, new_query, new_fragment))
    return new_url, count


# ─── Header processing ──────────────────────────────────────────────────────────

# Headers whose value IS a URL or bare hostname/host:port.
# Includes HTTP/2 pseudo-headers (:authority) and common proxy headers.
URL_HEADERS = {
    # Standard
    'host', 'origin', 'referer', 'location', 'content-location',
    'access-control-allow-origin', 'x-forwarded-host', 'x-original-url',
    'x-rewrite-url', 'link', 'via',
    # HTTP/2 pseudo-headers (Chrome/Firefox HAR files use these)
    ':authority', ':scheme',
    # Proxy / load-balancer headers
    'x-forwarded-for', 'x-real-ip', 'forwarded',
    # Other common headers that embed full URLs
    'x-request-url', 'x-proxy-url', 'x-amz-website-redirect-location',
}

COOKIE_HEADERS = {'cookie', 'set-cookie'}


def replace_in_header(name: str, value: str, old: str, new: str) -> tuple[str, int]:
    """
    Smart header-value replacement.

    Strategy:
      - URL_HEADERS  → try URL-aware replacement first; always also run plain
                       string replacement as a safety net (handles bare hostnames
                       that urlparse can mis-classify).
      - COOKIE_HEADERS → plain string (handles domain= attributes naturally).
      - Everything else → plain string (catches any header that embeds a domain).
    """
    if not value:
        return value, 0

    name_lower = name.lower()

    if name_lower in URL_HEADERS:
        new_val, n = replace_in_url(value, old, new)
        # Safety net: run plain replace on the result in case urlparse
        # failed to find the domain (e.g. bare "host:port" edge cases).
        new_val2, n2 = replace_domain_in_string(new_val, old, new)
        return new_val2, n + n2

    if name_lower in COOKIE_HEADERS:
        return replace_domain_in_string(value, old, new)

    # Generic: replace any occurrence (catches custom headers, authorization
    # server hints, etc. that might embed a domain).
    return replace_domain_in_string(value, old, new)


def process_headers(headers: list[dict], pairs: list[tuple[str,str]], verbose: bool, label: str) -> tuple[list[dict], int]:
    total = 0
    new_headers = []
    for h in headers:
        name  = h.get('name', '')
        value = h.get('value')
        if value is None:
            value = ''
        value = str(value)

        original_value = value
        n_total = 0
        for old, new in pairs:
            value, n = replace_in_header(name, value, old, new)
            n_total += n

        if n_total:
            if verbose:
                changed(f"  {label} header [{name}]: {original_value!r} → {value!r}")
            total += n_total
        new_h = dict(h)
        new_h['value'] = value
        new_headers.append(new_h)
    return new_headers, total


# ─── Body / content processing ─────────────────────────────────────────────────

def recalculate_content_length(body_bytes: bytes) -> int:
    return len(body_bytes)


def recalculate_content_md5(body_bytes: bytes) -> str:
    """Returns Base64-encoded MD5 as used in Content-MD5 header."""
    md5 = hashlib.md5(body_bytes).digest()
    return base64.b64encode(md5).decode('ascii')


def process_body_text(text: str, old: str, new: str) -> tuple[str, int]:
    """
    Process body text — tries JSON-aware replacement first,
    falls back to plain string replacement.
    """
    if not text:
        return text, 0

    # Try to parse as JSON and do deep replacement
    try:
        obj = json.loads(text)
        new_obj, count = deep_replace_in_obj(obj, old, new)
        if count:
            # Re-serialise preserving original formatting style
            new_text = json.dumps(new_obj, ensure_ascii=False, separators=(',', ':') if ' ' not in text[:2] else (', ', ': '))
            return new_text, count
    except (json.JSONDecodeError, ValueError):
        pass

    # Plain text replacement
    return replace_domain_in_string(text, old, new)


def deep_replace_in_obj(obj: Any, old: str, new: str) -> tuple[Any, int]:
    """Recursively replace domain in any JSON-like object."""
    count = 0
    if isinstance(obj, str):
        new_str, n = replace_domain_in_string(obj, old, new)
        return new_str, n
    elif isinstance(obj, dict):
        new_dict = {}
        for k, v in obj.items():
            new_k, nk = replace_domain_in_string(k, old, new) if isinstance(k, str) else (k, 0)
            new_v, nv = deep_replace_in_obj(v, old, new)
            new_dict[new_k] = new_v
            count += nk + nv
        return new_dict, count
    elif isinstance(obj, list):
        new_list = []
        for item in obj:
            new_item, n = deep_replace_in_obj(item, old, new)
            new_list.append(new_item)
            count += n
        return new_list, count
    else:
        return obj, 0


def process_post_data(post_data: dict, pairs: list[tuple[str,str]], verbose: bool) -> tuple[dict, int]:
    """Process HAR postData object."""
    if not post_data:
        return post_data, 0

    total = 0
    pd = copy.deepcopy(post_data)
    mime = pd.get('mimeType', '')

    # Replace in params (form fields)
    if 'params' in pd and pd['params']:
        new_params = []
        for p in pd['params']:
            new_name  = p.get('name', '')
            new_value = p.get('value', '')
            for old, new in pairs:
                new_name,  nn = replace_domain_in_string(new_name,  old, new)
                new_value, nv = replace_domain_in_string(new_value, old, new)
                total += nn + nv
            np_ = dict(p)
            np_['name']  = new_name
            np_['value'] = new_value
            new_params.append(np_)
        pd['params'] = new_params

    # Replace in text body
    if 'text' in pd and pd['text']:
        body = pd['text']
        n_total = 0
        for old, new in pairs:
            body, n = process_body_text(body, old, new)
            n_total += n
        if n_total:
            if verbose:
                changed(f"  POST body ({mime}): {n_total} replacement(s)")
            pd['text'] = body
            total += n_total

    return pd, total


def update_content_length_header(headers: list[dict], new_body: str, encoding: str = '') -> list[dict]:
    """
    Recalculate and update Content-Length (and Content-MD5 if present)
    after body modification.
    """
    if encoding and encoding.lower() == 'base64':
        body_bytes = base64.b64decode(new_body)
    else:
        body_bytes = new_body.encode('utf-8') if new_body else b''

    new_headers = []
    for h in headers:
        name_lower = h['name'].lower()
        if name_lower == 'content-length':
            new_len = str(recalculate_content_length(body_bytes))
            if h['value'] != new_len:
                h = dict(h)
                h['value'] = new_len
        elif name_lower == 'content-md5':
            new_md5 = recalculate_content_md5(body_bytes)
            if h['value'] != new_md5:
                h = dict(h)
                h['value'] = new_md5
        new_headers.append(h)
    return new_headers


# ─── Entry processing ───────────────────────────────────────────────────────────

def process_request(request: dict, pairs: list[tuple[str,str]], verbose: bool) -> tuple[dict, int]:
    req = copy.deepcopy(request)
    total = 0

    # URL — apply all pairs in sequence
    url = req.get('url', '')
    for old, new in pairs:
        new_url, n = replace_in_url(url, old, new)
        if n:
            if verbose: changed(f"  Request URL: {url!r} → {new_url!r}")
            total += n
        url = new_url
    req['url'] = url

    # Headers
    req['headers'], n = process_headers(req.get('headers', []), pairs, verbose, 'Req')
    total += n

    # Query string params
    if 'queryString' in req:
        new_qs = []
        for q in req['queryString']:
            qname  = q.get('name', '')
            qvalue = q.get('value', '')
            for old, new in pairs:
                qname,  nn  = replace_domain_in_string(qname,  old, new)
                qvalue, nv2 = replace_domain_in_string(qvalue, old, new)
                total += nn + nv2
            nq = dict(q); nq['name'] = qname; nq['value'] = qvalue
            new_qs.append(nq)
        req['queryString'] = new_qs

    # Cookies
    if 'cookies' in req:
        new_cookies = []
        for c in req['cookies']:
            cval = c.get('value', '')
            cdom = c.get('domain', '')
            for old, new in pairs:
                cval, n2 = replace_domain_in_string(cval, old, new)
                cdom, n3 = replace_domain_in_string(cdom, old, new)
                total += n2 + n3
            nc = dict(c); nc['value'] = cval; nc['domain'] = cdom
            new_cookies.append(nc)
        req['cookies'] = new_cookies

    # POST data
    if 'postData' in req and req['postData']:
        new_pd, n = process_post_data(req['postData'], pairs, verbose)
        total += n
        req['postData'] = new_pd

        # Recalculate Content-Length after body change
        if n:
            body_text = new_pd.get('text', '')
            req['headers'] = update_content_length_header(req['headers'], body_text)
            if verbose: info("  Recalculated Content-Length for request body")

    # bodySize recalculation
    if req.get('postData') and 'text' in req['postData']:
        body_bytes = req['postData']['text'].encode('utf-8')
        req['bodySize'] = len(body_bytes)

    return req, total


def process_response(response: dict, pairs: list[tuple[str,str]], verbose: bool) -> tuple[dict, int]:
    resp = copy.deepcopy(response)
    total = 0

    # Headers
    resp['headers'], n = process_headers(resp.get('headers', []), pairs, verbose, 'Resp')
    total += n

    # Cookies
    if 'cookies' in resp:
        new_cookies = []
        for c in resp['cookies']:
            cval = c.get('value', '')
            cdom = c.get('domain', '')
            for old, new in pairs:
                cval, n2 = replace_domain_in_string(cval, old, new)
                cdom, n3 = replace_domain_in_string(cdom, old, new)
                total += n2 + n3
            nc = dict(c); nc['value'] = cval; nc['domain'] = cdom
            new_cookies.append(nc)
        resp['cookies'] = new_cookies

    # Response body content
    content = resp.get('content', {})
    if content:
        mime     = content.get('mimeType', '')
        encoding = content.get('encoding', '')
        text     = content.get('text', '')

        if text:
            if encoding.lower() == 'base64':
                # Decode → process all pairs → re-encode
                try:
                    decoded = base64.b64decode(text).decode('utf-8', errors='replace')
                    n_total = 0
                    for old, new in pairs:
                        decoded, n = process_body_text(decoded, old, new)
                        n_total += n
                    if n_total:
                        new_text = base64.b64encode(decoded.encode('utf-8')).decode('ascii')
                        if verbose: changed(f"  Response content (base64, {mime}): {n_total} replacement(s)")
                        content = dict(content)
                        content['text'] = new_text
                        content['size'] = len(decoded.encode('utf-8'))
                        total += n_total
                except Exception as e:
                    warn(f"  Could not decode base64 content: {e}")
            else:
                n_total = 0
                for old, new in pairs:
                    text, n = process_body_text(text, old, new)
                    n_total += n
                if n_total:
                    if verbose: changed(f"  Response content ({mime}): {n_total} replacement(s)")
                    content = dict(content)
                    content['text'] = text
                    content['size'] = len(text.encode('utf-8'))
                    total += n_total

        resp['content'] = content

        # Recalculate Content-Length / Content-MD5 after body change
        if total:
            body_text = content.get('text', '')
            encoding  = content.get('encoding', '')
            resp['headers'] = update_content_length_header(resp['headers'], body_text, encoding)
            if verbose: info("  Recalculated Content-Length for response body")

    return resp, total


def process_entry(entry: dict, pairs: list[tuple[str,str]], verbose: bool, idx: int) -> tuple[dict, int]:
    e = copy.deepcopy(entry)
    total = 0

    req_changes  = 0
    resp_changes = 0

    if 'request' in e:
        e['request'], req_changes = process_request(e['request'], pairs, verbose)
        total += req_changes

    if 'response' in e:
        e['response'], resp_changes = process_response(e['response'], pairs, verbose)
        total += resp_changes

    if total and verbose:
        method = e.get('request', {}).get('method', '?')
        url    = e.get('request', {}).get('url', '?')
        info(f"Entry #{idx+1} [{method}] {url[:80]} — {total} change(s)")

    return e, total


# ─── HAR-level processing ───────────────────────────────────────────────────────

def process_har(har: dict, pairs: list[tuple[str,str]], verbose: bool) -> tuple[dict, int]:
    """
    Apply all (old, new) replacement pairs to the entire HAR structure.
    Pairs are applied in order on each field — later pairs operate on the
    already-substituted text, so ordering matters when domains overlap.
    """
    har_out = copy.deepcopy(har)
    total   = 0

    log_node = har_out.get('log', {})

    # Creator / browser metadata
    for key in ('creator', 'browser'):
        if key in log_node:
            s = json.dumps(log_node[key])
            for old, new in pairs:
                s, n = replace_domain_in_string(s, old, new)
                total += n
            log_node[key] = json.loads(s)

    # Pages
    for page in log_node.get('pages', []):
        for field in ('title', 'id'):
            if field in page:
                for old, new in pairs:
                    page[field], n = replace_domain_in_string(page[field], old, new)
                    total += n

    # Entries
    entries = log_node.get('entries', [])
    new_entries = []
    for i, entry in enumerate(entries):
        new_entry, n = process_entry(entry, pairs, verbose, i)
        new_entries.append(new_entry)
        total += n

    log_node['entries'] = new_entries
    har_out['log'] = log_node
    return har_out, total


# ─── CLI ────────────────────────────────────────────────────────────────────────

def parse_map_file(path: str) -> list[tuple[str, str]]:
    """
    Load replacement pairs from a CSV or TSV map file.

    Supported formats (auto-detected):
      CSV:  old_domain,new_domain
      TSV:  old_domain<TAB>new_domain

    Lines starting with '#' are treated as comments and ignored.
    Blank lines are skipped.
    """
    import csv
    pairs = []
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Auto-detect delimiter
    delimiter = '\t' if '\t' in content else ','

    for row in csv.reader(content.splitlines(), delimiter=delimiter):
        if not row:
            continue
        if row[0].strip().startswith('#'):
            continue
        if len(row) < 2:
            warn(f"  Skipping map file row (need 2 columns): {row}")
            continue
        old, new = row[0].strip(), row[1].strip()
        if old and new:
            pairs.append((old, new))
    return pairs


def main():
    parser = argparse.ArgumentParser(
        description='Replace one or more domains in a HAR file, recalculating Content-Length and Content-MD5.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Single pair (original syntax still works)
  python har_replacer.py -i capture.har -o out.har -old example.com -new newsite.com

  # Multiple pairs via repeated -replace flags
  python har_replacer.py -i capture.har -o out.har \\
      -replace example.com newsite.com \\
      -replace api.example.com api.newsite.com \\
      -replace cdn.example.com cdn.newsite.com

  # Multiple pairs from a CSV/TSV map file
  python har_replacer.py -i capture.har -o out.har --map replacements.csv

  # Mix of -replace and --map
  python har_replacer.py -i capture.har -o out.har \\
      --map replacements.csv \\
      -replace extra.com extra.newsite.com --verbose

Map file format (CSV or TSV, # = comment):
  # old_domain,new_domain
  example.com,newsite.com
  api.example.com,api.newsite.com
  cdn.example.com,cdn.newsite.com
        """
    )
    parser.add_argument('-i', '--input',   required=True,  help='Input HAR file path')
    parser.add_argument('-o', '--output',  required=True,  help='Output HAR file path')

    # ── Multi-pair interface ───────────────────────────────────────────────────
    parser.add_argument(
        '-replace', '--replace',
        nargs=2, metavar=('OLD', 'NEW'),
        action='append', dest='replace_pairs', default=[],
        help='Domain pair to replace: -replace old.com new.com  (repeatable)'
    )
    parser.add_argument(
        '--map',
        metavar='FILE',
        help='CSV or TSV file with replacement pairs: old_domain,new_domain (one per line)'
    )

    # ── Legacy single-pair interface (kept for backwards compatibility) ────────
    parser.add_argument('-old', '--old-domain', dest='old_domain',
                        help='[Legacy] Single domain to replace')
    parser.add_argument('-new', '--new-domain', dest='new_domain',
                        help='[Legacy] Single replacement domain')

    parser.add_argument('--verbose', '-v', action='store_true',
                        help='Print every change made')
    parser.add_argument('--indent', type=int, default=2,
                        help='JSON indentation in output file (default: 2)')
    args = parser.parse_args()

    # ── Build final pairs list ─────────────────────────────────────────────────
    pairs: list[tuple[str, str]] = []

    # 1. Map file (loaded first so CLI flags can override/append)
    if args.map:
        try:
            map_pairs = parse_map_file(args.map)
            pairs.extend(map_pairs)
        except FileNotFoundError:
            error(f"Map file not found: {args.map}")
            sys.exit(1)
        except Exception as e:
            error(f"Failed to parse map file: {e}")
            sys.exit(1)

    # 2. Repeated -replace flags
    for old, new in args.replace_pairs:
        pairs.append((old, new))

    # 3. Legacy -old / -new (backwards compat)
    if args.old_domain and args.new_domain:
        pairs.append((args.old_domain, args.new_domain))
    elif args.old_domain or args.new_domain:
        error("Both -old and -new must be supplied together.")
        sys.exit(1)

    if not pairs:
        error("No replacement pairs supplied. Use -replace OLD NEW, --map FILE, or -old/-new.")
        sys.exit(1)

    # Warn about duplicates
    seen = set()
    for old, new in pairs:
        if old in seen:
            warn(f"  Duplicate old-domain '{old}' — it appears more than once in the replacement list.")
        seen.add(old)

    # ── Load ──────────────────────────────────────────────────────────────────
    log(f"\n{BOLD}HAR Domain Replacer{RESET}", BOLD)
    log(f"  Input  : {args.input}")
    log(f"  Output : {args.output}")
    log(f"  Pairs  : {len(pairs)}")
    for old, new in pairs:
        log(f"           {RED}{old}{RESET}  →  {GREEN}{new}{RESET}")
    print()

    try:
        with open(args.input, 'r', encoding='utf-8') as f:
            har = json.load(f)
    except FileNotFoundError:
        error(f"Input file not found: {args.input}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        error(f"Invalid JSON in HAR file: {e}")
        sys.exit(1)

    entry_count = len(har.get('log', {}).get('entries', []))
    log(f"  Loaded {entry_count} entries from HAR file.\n")

    # ── Process ───────────────────────────────────────────────────────────────
    new_har, total_changes = process_har(har, pairs, args.verbose)

    # ── Per-pair summary ──────────────────────────────────────────────────────
    if len(pairs) > 1 and not args.verbose:
        pass  # aggregate total is shown below

    # ── Save ──────────────────────────────────────────────────────────────────
    try:
        with open(args.output, 'w', encoding='utf-8') as f:
            json.dump(new_har, f, ensure_ascii=False, indent=args.indent)
    except IOError as e:
        error(f"Could not write output file: {e}")
        sys.exit(1)

    log(f"\n{BOLD}Done.{RESET} Total replacements: {GREEN}{total_changes}{RESET}")
    log(f"Output written to: {args.output}\n")


if __name__ == '__main__':
    main()

