#!/usr/bin/env python3
"""test.sh が使う Backlog API の偽サーバー。ループバックだけで待ち受ける。

使い方: fake_backlog_server.py <ポート番号を書くファイル> <要求を記録するファイル>
受けた要求は「メソッド パス 問い合わせ文字列」の形で1行ずつ記録する（apiKey の値は伏せる）。
GET 以外のメソッドは記録したうえで 405 を返す。
"""

import json
import re
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlsplit

API_KEY = "test-key-0001"
ISSUE_TOTAL = 250
COMMENT_TOTAL = 150
STATUSES = [
    {"id": 1, "name": "未対応"},
    {"id": 2, "name": "処理中"},
    {"id": 3, "name": "処理済み"},
    {"id": 4, "name": "完了"},
]
USER = {"id": 1, "userId": "test_user_01", "name": "山田太郎"}


def make_issue(number):
    status = STATUSES[number % 4]
    return {
        "id": 1000 + number,
        "issueKey": "TEST-%d" % number,
        "summary": "テスト課題 %d" % number,
        "status": status,
        "assignee": USER if number % 2 else None,
        "priority": {"id": 3, "name": "中"},
        "dueDate": "2026-10-%02dT00:00:00Z" % (number % 28 + 1),
        "created": "2026-01-01T00:00:00Z",
        "createdUser": USER,
        "updated": "2026-10-01T%02d:00:00Z" % (number % 24),
        "description": "課題 %d の本文。\n2行目。" % number,
    }


ISSUES = [make_issue(number) for number in range(ISSUE_TOTAL, 0, -1)]
COMMENTS = [
    {"id": 5000 + index, "content": "コメント %d" % index, "createdUser": USER,
     "created": "2026-10-01T00:00:00Z", "changeLog": []}
    for index in range(1, COMMENT_TOTAL + 1)
]


class Handler(BaseHTTPRequestHandler):
    log_path = None

    def log_message(self, *args):
        return

    def record(self):
        parts = urlsplit(self.path)
        query = re.sub(r"apiKey=[^&]*", "apiKey=***", parts.query)
        with open(self.log_path, "a", encoding="utf-8") as handle:
            handle.write("%s %s %s\n" % (self.command, parts.path, query))

    def reply(self, status, payload):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def reject(self):
        self.record()
        self.reply(405, {"errors": [{"message": "method not allowed"}]})

    do_POST = do_PUT = do_PATCH = do_DELETE = reject

    def do_GET(self):
        self.record()
        parts = urlsplit(self.path)
        query = parse_qs(parts.query)
        if query.get("apiKey", [""])[0] != API_KEY:
            return self.reply(401, {"errors": [{"message": "Authentication failure."}]})
        path = parts.path[len("/api/v2/"):] if parts.path.startswith("/api/v2/") else ""
        if path == "users/myself":
            return self.reply(200, USER)
        if path == "projects":
            return self.reply(200, [{"id": 10, "projectKey": "TEST", "name": "テスト用プロジェクト", "archived": False}])
        if path == "projects/TEST":
            return self.reply(200, {"id": 10, "projectKey": "TEST", "name": "テスト用プロジェクト"})
        if path == "projects/TEST/statuses":
            return self.reply(200, STATUSES)
        if path in ("issues", "issues/count"):
            items = ISSUES
            wanted = {int(value) for value in query.get("statusId[]", [])}
            if wanted:
                items = [item for item in items if item["status"]["id"] in wanted]
            keyword = query.get("keyword", [""])[0]
            if keyword:
                items = [item for item in items if keyword in item["summary"]]
            if path.endswith("/count"):
                return self.reply(200, {"count": len(items)})
            count = min(int(query.get("count", ["20"])[0]), 100)
            offset = int(query.get("offset", ["0"])[0])
            return self.reply(200, items[offset:offset + count])
        matched = re.match(r"^issues/(TEST-\d+)(/comments)?$", path)
        if matched:
            number = int(matched.group(1).split("-")[1])
            if number < 1 or number > ISSUE_TOTAL:
                return self.reply(404, {"errors": [{"message": "No issue."}]})
            if not matched.group(2):
                return self.reply(200, make_issue(number))
            if number != 1:
                return self.reply(200, [])
            count = min(int(query.get("count", ["20"])[0]), 100)
            min_id = int(query.get("minId", ["0"])[0])
            items = [item for item in COMMENTS if item["id"] >= min_id]
            return self.reply(200, items[:count])
        return self.reply(404, {"errors": [{"message": "No such path."}]})


def main():
    port_file, log_file = sys.argv[1], sys.argv[2]
    Handler.log_path = log_file
    server = HTTPServer(("127.0.0.1", 0), Handler)
    with open(port_file, "w", encoding="utf-8") as handle:
        handle.write(str(server.server_address[1]))
    server.serve_forever()


if __name__ == "__main__":
    main()
