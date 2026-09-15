#!/usr/bin/env python3
"""
Agent Adapter Proxy for KoboldCPP
=================================
Bridges KoboldCPP with modern agentic frameworks (Goose, OpenCode, Claude Code).
Solves:
1. Streaming tool call desynchronization (KoboldCPP doesn't stream delta.tool_calls)
2. Multi-tool sequential extraction per turn (write + compile/run in same turn)
3. Robust tool argument parsing (tolerant to raw newlines, nested braces, unescaped tokens)
4. Lazy placeholder auto-resolution (converts "<contents of the above code>" to actual code)
5. Markdown code block & shell block auto-detection when models output markdown instead of tool calls
6. Token truncation (ensures adequate generation headroom for code files)
7. Sequential execution guarantee (ensures all file writes execute before shell compilation)
"""

import http.server
import urllib.request
import json
import re
import uuid
import sys
import argparse

DEFAULT_TARGET = "http://127.0.0.1:5001"
DEFAULT_PORT = 5002

def is_placeholder_content(text):
    if not text:
        return True
    s = text.strip()
    if s.startswith("<") and s.endswith(">"):
        return True
    if len(s) < 100 and any(p in s.lower() for p in [
        "contents of", "code above", "same as above", "rest of code",
        "insert code", "unchanged", "the above code", "previous code"
    ]):
        return True
    return False

def find_code_block_for_extension(ext, content, messages=None):
    lang_map = {
        "cpp": ["cpp", "c\\+\\+", "cxx", "cc", "c"],
        "h": ["cpp", "c\\+\\+", "cxx", "c", "h"],
        "hpp": ["cpp", "c\\+\\+", "cxx", "c", "h", "hpp"],
        "py": ["python", "py"],
        "sh": ["bash", "sh", "shell", "zsh"],
        "json": ["json"]
    }
    langs = lang_map.get(ext.lower(), [ext.lower()])
    pattern = r"```(?:" + "|".join(langs) + r")\n(.*?)```"

    # Search in current content first
    if content:
        matches = list(re.finditer(pattern, content, re.DOTALL))
        if matches:
            return matches[-1].group(1).strip()

    # Search backwards in previous messages
    if messages:
        for msg in reversed(messages):
            c = msg.get("content") or ""
            if isinstance(c, str):
                m = list(re.finditer(pattern, c, re.DOTALL))
                if m:
                    return m[-1].group(1).strip()
    return None

def extract_filename_for_code(code_str, content, messages=None, default_name="solution.cpp"):
    # 1. Search text before or after code block for explicit file indicators
    patterns = [
        r"(?:file|create|write|writing|implementing|in|into|update|modify|to|for|named|save\s+to|code\s+in)\s+(?:the\s+)?(?:file\s+)?(?:code\s+for\s+)?[`\"]?([a-zA-Z0-9_\-\./]+\.(?:cpp|h|hpp|c|py|rs|zig|json|txt))[`\"]?",
        r"[`\"]([a-zA-Z0-9_\-\./]+\.(?:cpp|h|hpp|c|py|rs|zig|json|txt))[`\"]"
    ]
    for pat in patterns:
        m = re.search(pat, content, re.IGNORECASE)
        if m:
            return m.group(1).strip()

    # 2. Check compilation commands in content
    cm = re.search(r"g\+\+.*?([a-zA-Z0-9_\-\./]+\.cpp)", content)
    if cm:
        return cm.group(1).strip()

    # 3. Check user prompts in messages history
    if messages:
        for msg in reversed(messages):
            if msg.get("role") == "user":
                c = msg.get("content") or ""
                if isinstance(c, str):
                    fm = re.search(r"[`\"]?([a-zA-Z0-9_\-\./]+\.(?:cpp|h|hpp|c|py|rs|zig|json|txt))[`\"]?", c)
                    if fm:
                        return fm.group(1).strip()

    return default_name

def extract_tools_from_text(content, messages=None):
    calls = []
    if not content:
        return calls

    # 1. Structured JSON: {"name": "write", "arguments": {"path": ..., "content": ...}}
    for m in re.finditer(r'\{\s*"name"\s*:\s*"write"\s*,\s*"arguments"\s*:\s*\{.*?"path"\s*:\s*"([^"]+)".*?"content"\s*:\s*"(.*?)"\s*\}\s*\}', content, re.DOTALL):
        path = m.group(1)
        raw = m.group(2)
        try:
            fc = json.loads(f'"{raw}"', strict=False)
        except Exception:
            fc = raw.replace('\\"', '"').replace('\\n', '\n').replace('\\t', '\t')
        calls.append({
            "id": f"call_{uuid.uuid4().hex[:8]}",
            "type": "function",
            "function": {"name": "write", "arguments": json.dumps({"path": path, "content": fc})}
        })

    # 2. XML tags: <write path="..." ...>
    if not any(c['function']['name'] == 'write' for c in calls):
        for m in re.finditer(r'<(?:write|file)\s+path=[\"\'](.*?)[\"\'](?:\s+content=[\"\'](.*?)[\"\'])?(?:\s*/>|>(.*?)</(?:write|file)>)', content, re.DOTALL):
            path = m.group(1).strip()
            fc = (m.group(2) or m.group(3) or '').strip()
            if path:
                calls.append({
                    "id": f"call_{uuid.uuid4().hex[:8]}",
                    "type": "function",
                    "function": {"name": "write", "arguments": json.dumps({"path": path, "content": fc})}
                })

    # 3. Structured JSON: {"name": "shell", "arguments": {"command": ...}}
    for m in re.finditer(r'\{\s*"name"\s*:\s*"shell"\s*,\s*"arguments"\s*:\s*\{.*?"command"\s*:\s*"([^"]+)".*?\}\s*\}', content, re.DOTALL):
        cmd = m.group(1).replace('\\"', '"').replace('\\\\', '\\')
        calls.append({
            "id": f"call_{uuid.uuid4().hex[:8]}",
            "type": "function",
            "function": {"name": "shell", "arguments": json.dumps({"command": cmd})}
        })

    # 4. XML tags: <shell command="..." />
    for m in re.finditer(r'<(?:shell|bash|execute)(?:\s+command=[\"\'](.*?)[\"\'])?(?:\s*/>|>(.*?)</(?:shell|bash|execute)>)', content, re.DOTALL):
        cmd = (m.group(1) or m.group(2) or '').strip()
        if cmd and not any(c['function'].get('arguments', '') == json.dumps({"command": cmd}) for c in calls):
            calls.append({
                "id": f"call_{uuid.uuid4().hex[:8]}",
                "type": "function",
                "function": {"name": "shell", "arguments": json.dumps({"command": cmd})}
            })

    # 5. Markdown fallback: check for ```cpp / ```python code blocks if no valid write call exists
    code_matches = list(re.finditer(r'```(?:cpp|c\+\+|c|python|py|rust|zig|json)\n(.*?)```', content, re.DOTALL))
    if code_matches:
        for cm in code_matches:
            code_text = cm.group(1).strip()
            if not any(c['function']['name'] == 'write' for c in calls):
                path = extract_filename_for_code(code_text, content, messages)
                calls.append({
                    "id": f"call_{uuid.uuid4().hex[:8]}",
                    "type": "function",
                    "function": {"name": "write", "arguments": json.dumps({"path": path, "content": code_text})}
                })

    # 6. Markdown fallback for shell commands: check for ```bash ... ```
    bash_matches = list(re.finditer(r'```(?:bash|sh|shell|zsh)\n(.*?)```', content, re.DOTALL))
    if bash_matches:
        for bm in bash_matches:
            cmd = bm.group(1).strip()
            if cmd and not any(c['function']['name'] == 'shell' for c in calls):
                calls.append({
                    "id": f"call_{uuid.uuid4().hex[:8]}",
                    "type": "function",
                    "function": {"name": "shell", "arguments": json.dumps({"command": cmd})}
                })

    # 7. Auto-chain compile/test command if user prompt asked for g++ and we wrote a .cpp file
    if any(c['function']['name'] == 'write' for c in calls) and not any(c['function']['name'] == 'shell' for c in calls):
        for c in calls:
            if c['function']['name'] == 'write':
                try:
                    args = json.loads(c['function']['arguments'])
                    p = args.get('path', '')
                    if p.endswith('.cpp'):
                        bin_name = p[:-4]
                        compile_cmd = f"g++ -std=c++17 -Wall -O2 {p} -o {bin_name} && ./{bin_name}"
                        calls.append({
                            "id": f"call_{uuid.uuid4().hex[:8]}",
                            "type": "function",
                            "function": {"name": "shell", "arguments": json.dumps({"command": compile_cmd})}
                        })
                        break
                except Exception:
                    pass

    return calls

class ProxyHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        url = f"{self.server.target_host}{self.path}"
        req = urllib.request.Request(url, headers=dict(self.headers))
        try:
            with urllib.request.urlopen(req) as resp:
                self.send_response(resp.status)
                for k, v in resp.getheaders():
                    if k.lower() not in ('transfer-encoding', 'content-length'):
                        self.send_header(k, v)
                data = resp.read()
                self.send_header('Content-Length', str(len(data)))
                self.end_headers()
                self.wfile.write(data)
        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            self.end_headers()
            self.wfile.write(e.read())
        except Exception as e:
            self.send_response(502)
            self.end_headers()
            self.wfile.write(str(e).encode('utf-8'))

    def do_POST(self):
        url = f"{self.server.target_host}{self.path}"
        content_len = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_len) if content_len > 0 else b''

        if self.path == '/v1/chat/completions':
            self.handle_chat_completions(url, body)
        else:
            self.forward_post(url, body)

    def forward_post(self, url, body):
        req = urllib.request.Request(url, data=body, headers=dict(self.headers))
        try:
            with urllib.request.urlopen(req) as resp:
                self.send_response(resp.status)
                for k, v in resp.getheaders():
                    if k.lower() not in ('transfer-encoding', 'content-length'):
                        self.send_header(k, v)
                data = resp.read()
                self.send_header('Content-Length', str(len(data)))
                self.end_headers()
                self.wfile.write(data)
        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            self.end_headers()
            self.wfile.write(e.read())
        except Exception as e:
            self.send_response(502)
            self.end_headers()
            self.wfile.write(str(e).encode('utf-8'))

    def handle_chat_completions(self, url, body):
        try:
            payload = json.loads(body.decode('utf-8'))
        except Exception:
            return self.forward_post(url, body)

        # 1. Manage generation token limits: ensure 3072 tokens for full file generation
        req_max = payload.get('max_tokens') or payload.get('max_completion_tokens')
        if not req_max or req_max < 2048:
            payload['max_tokens'] = 3072
        elif req_max > 4096:
            payload['max_tokens'] = 3072
        else:
            payload['max_tokens'] = req_max

        # 2. Inject system instructions to prevent placeholder abbreviations & ensure write before compile
        system_reminder = (
            "\n\n[TOOL EXECUTION RULES]\n"
            "1. When calling the 'write' tool, the 'content' argument MUST be the COMPLETE file content from start to finish. "
            "NEVER use placeholders like '<contents of...>' or '// unchanged'.\n"
            "2. When writing and running code, call 'write' first to write the file, then call 'shell' to compile and run.\n"
            "3. Ensure all C++ class member variables (e.g. currentJobs, bestJobs, slot) are declared before use."
        )
        messages = payload.get('messages', [])
        if messages and messages[0].get('role') == 'system':
            if "[TOOL EXECUTION RULES]" not in (messages[0].get('content') or ''):
                messages[0]['content'] = (messages[0].get('content') or '') + system_reminder

        has_tools = bool(payload.get('tools'))
        client_stream = payload.get('stream', False)

        if not has_tools:
            # Regular chat or title generation - forward directly with client's stream preference
            new_body = json.dumps(payload).encode('utf-8')
            headers = dict(self.headers)
            headers['Content-Length'] = str(len(new_body))
            req = urllib.request.Request(url, data=new_body, headers=headers)
            try:
                with urllib.request.urlopen(req) as resp:
                    self.send_response(resp.status)
                    for k, v in resp.getheaders():
                        if k.lower() != 'content-length' and client_stream:
                            self.send_header(k, v)
                        elif not client_stream and k.lower() not in ('transfer-encoding', 'content-length'):
                            self.send_header(k, v)
                    self.end_headers()
                    while True:
                        chunk = resp.read(1024)
                        if not chunk:
                            break
                        self.wfile.write(chunk)
                        self.wfile.flush()
            except urllib.error.HTTPError as e:
                self.send_response(e.code)
                self.end_headers()
                self.wfile.write(e.read())
            except Exception as e:
                self.send_response(502)
                self.end_headers()
                self.wfile.write(str(e).encode('utf-8'))
            return

        # Request HAS tools! KoboldCPP parses tools reliably with stream=false
        payload['stream'] = False
        new_body = json.dumps(payload).encode('utf-8')
        headers = dict(self.headers)
        headers['Content-Length'] = str(len(new_body))
        headers['Content-Type'] = 'application/json'
        req = urllib.request.Request(url, data=new_body, headers=headers)

        try:
            with urllib.request.urlopen(req) as resp:
                resp_data = resp.read()
                resp_json = json.loads(resp_data.decode('utf-8'))
        except Exception as e:
            self.send_response(500)
            self.end_headers()
            self.wfile.write(str(e).encode('utf-8'))
            return

        choice = resp_json.get('choices', [{}])[0]
        msg = choice.get('message', {})
        content = msg.get('content', '') or ''
        tool_calls = msg.get('tool_calls', []) or []

        # Extract any tools from text or markdown fallbacks
        extra_calls = extract_tools_from_text(content, messages)
        existing_names = {tc['function']['name'] for tc in tool_calls}
        for ec in extra_calls:
            if ec['function']['name'] not in existing_names:
                tool_calls.append(ec)
                existing_names.add(ec['function']['name'])

        # Resolve any lazy placeholder content in write calls
        for tc in tool_calls:
            if tc['function']['name'] == 'write':
                try:
                    args = json.loads(tc['function']['arguments'])
                    if is_placeholder_content(args.get('content', '')):
                        ext = args.get('path', '').split('.')[-1]
                        real_code = find_code_block_for_extension(ext, content, messages)
                        if real_code:
                            args['content'] = real_code
                            tc['function']['arguments'] = json.dumps(args)
                except Exception:
                    pass

        # CRITICAL: Always order write calls BEFORE shell calls
        tool_calls.sort(key=lambda tc: 0 if tc['function']['name'] == 'write' else 1)

        if tool_calls:
            choice['message']['tool_calls'] = tool_calls
            choice['finish_reason'] = "tool_calls"

        if not client_stream:
            out_bytes = json.dumps(resp_json).encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(out_bytes)))
            self.end_headers()
            self.wfile.write(out_bytes)
            return

        # Client requested streaming SSE
        cmpl_id = resp_json.get('id', f'chatcmpl-{uuid.uuid4().hex[:8]}')
        model = resp_json.get('model', 'local')
        created = resp_json.get('created', 0)

        self.send_response(200)
        self.send_header('Content-Type', 'text/event-stream')
        self.send_header('Cache-Control', 'no-cache')
        self.send_header('Connection', 'keep-alive')
        self.end_headers()

        def send_chunk(delta, finish_reason=None):
            chunk = {
                "id": cmpl_id,
                "object": "chat.completion.chunk",
                "created": created,
                "model": model,
                "choices": [{
                    "index": 0,
                    "delta": delta,
                    "finish_reason": finish_reason
                }]
            }
            line = f"data: {json.dumps(chunk)}\n\n".encode('utf-8')
            self.wfile.write(line)
            self.wfile.flush()

        send_chunk({"role": "assistant"})

        if tool_calls:
            for idx, tc in enumerate(tool_calls):
                send_chunk({
                    "tool_calls": [{
                        "index": idx,
                        "id": tc["id"],
                        "type": "function",
                        "function": {
                            "name": tc["function"]["name"],
                            "arguments": tc["function"]["arguments"]
                        }
                    }]
                })
            send_chunk({}, finish_reason="tool_calls")
        else:
            if content:
                send_chunk({"content": content})
            send_chunk({}, finish_reason="stop")

        self.wfile.write(b"data: [DONE]\n\n")
        self.wfile.flush()

    def log_message(self, format, *args):
        sys.stderr.write(f"[Adapter] {args[0]} {args[1]}\n")

class CustomHTTPServer(http.server.ThreadingHTTPServer):
    def __init__(self, server_address, RequestHandlerClass, target_host):
        self.target_host = target_host
        super().__init__(server_address, RequestHandlerClass)

def main():
    parser = argparse.ArgumentParser(description="Agent Adapter Proxy for KoboldCPP")
    parser.add_argument("--listen-port", type=int, default=DEFAULT_PORT, help="Port to listen on")
    parser.add_argument("--target-host", type=str, default=DEFAULT_TARGET, help="KoboldCPP upstream URL")
    args = parser.parse_args()

    server = CustomHTTPServer(('127.0.0.1', args.listen_port), ProxyHandler, args.target_host)
    print(f"Agent Adapter Proxy listening on 127.0.0.1:{args.listen_port} -> {args.target_host}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass

if __name__ == '__main__':
    main()
