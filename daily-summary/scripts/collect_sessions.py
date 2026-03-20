#!/usr/bin/env python3
"""
collect_sessions.py — Claude Code 세션 파일 수집기

Usage:
    python3 collect_sessions.py [YYYY-MM-DD]

인자가 없으면 오늘 날짜를 기준으로 수집한다.
"""

import os
import sys
import json
import glob
from datetime import datetime, date, timezone


def extract_text(content) -> str:
    """message content에서 텍스트를 추출한다."""
    if isinstance(content, list):
        for c in content:
            if isinstance(c, dict) and c.get("type") == "text":
                return c["text"]
        return ""
    elif isinstance(content, str):
        return content
    return ""


def parse_timestamp(ts_raw: str):
    """ISO 타임스탬프를 로컬 시간 datetime으로 변환한다."""
    if not ts_raw:
        return None
    try:
        return datetime.fromisoformat(ts_raw.replace("Z", "+00:00")).astimezone()
    except ValueError:
        return None


def collect(target_date: date) -> list[dict]:
    projects_dir = os.path.expanduser("~/.claude/projects")
    sessions = []

    for jsonl_path in glob.glob(f"{projects_dir}/**/*.jsonl", recursive=True):
        mtime = datetime.fromtimestamp(os.path.getmtime(jsonl_path))
        if mtime.date() != target_date:
            continue

        project = os.path.basename(os.path.dirname(jsonl_path))
        messages = []

        with open(jsonl_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    d = json.loads(line)
                except json.JSONDecodeError:
                    continue

                role = d.get("type")
                # system-reminder 등 시스템 메시지 제외
                if role not in ("user", "assistant"):
                    continue

                ts = parse_timestamp(d.get("timestamp", ""))
                content = d.get("message", {}).get("content", "")
                text = extract_text(content).strip()

                # 빈 메시지 또는 로컬 명령 결과 제외
                if not text or "<local-command-caveat>" in text:
                    continue

                messages.append({
                    "role": role,
                    "ts": ts,
                    "text": text,
                })

        if not messages:
            continue

        start_ts = next((m["ts"] for m in messages if m["ts"]), None)
        sessions.append({
            "file": jsonl_path,
            "project": project,
            "start": start_ts,
            "messages": messages,
        })

    sessions.sort(
        key=lambda s: s["start"] or datetime.min.replace(tzinfo=timezone.utc)
    )

    return [
        {
            "project": s["project"],
            "start": s["start"].strftime("%H:%M") if s["start"] else "?",
            "message_count": len(s["messages"]),
            "messages": [
                {
                    "role": m["role"],
                    "ts": m["ts"].strftime("%H:%M") if m["ts"] else "?",
                    "text": m["text"][:300],
                }
                for m in s["messages"]
            ],
        }
        for s in sessions
    ]


if __name__ == "__main__":
    if len(sys.argv) > 1:
        try:
            target_date = date.fromisoformat(sys.argv[1])
        except ValueError:
            print(f"오류: 날짜 형식이 잘못되었습니다 → '{sys.argv[1]}' (형식: YYYY-MM-DD)", file=sys.stderr)
            sys.exit(1)
    else:
        target_date = date.today()

    result = collect(target_date)
    print(json.dumps(result, ensure_ascii=False, indent=2))