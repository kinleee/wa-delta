"""WA delta watcher. Reads the Windows toast database (read-only) and prints one
JSON object per line:
  {"t": "start", "last": N}
  {"t": "msg", "id": N, "sender": "...", "text": "..."}   a WhatsApp message toast
  {"t": "idle", "sec": S}                                   every TICK seconds
It never touches WhatsApp; the plugin decides what to do."""
import ctypes, json, os, re, sqlite3, sys, time

TICK = 3
DB = os.path.expandvars(r"%LOCALAPPDATA%\Microsoft\Windows\Notifications\wpndatabase.db")
Q = """select n.Id, n.Payload from Notification n join NotificationHandler h on h.RecordId=n.HandlerId
       where h.PrimaryId like '%WhatsAppDesktop%' and n.Id > ? order by n.Id"""


class LASTINPUTINFO(ctypes.Structure):
    _fields_ = [("cbSize", ctypes.c_uint), ("dwTime", ctypes.c_uint)]


def idle_seconds():
    li = LASTINPUTINFO(ctypes.sizeof(LASTINPUTINFO), 0)
    ctypes.windll.user32.GetLastInputInfo(ctypes.byref(li))
    return (ctypes.windll.kernel32.GetTickCount() - li.dwTime) / 1000.0


def fetch(after):
    con = sqlite3.connect(f"file:{DB}?mode=ro", uri=True, timeout=5)
    try:
        return con.execute(Q, (after,)).fetchall()
    finally:
        con.close()


def parse(payload):
    s = payload.decode("utf-8", "replace") if isinstance(payload, bytes) else payload
    if "quickReplyInputBoxId" not in s:  # badges, downloads, calls
        return None
    texts = [re.sub(r"\s+", " ", t).strip() for t in re.findall(r"<text[^>]*>(.*?)</text>", s, re.S)]
    texts = [t.replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">").replace("&quot;", '"') for t in texts]
    body = [t for t in texts[1:] if not re.match(r"^✉ \d+ unread messages?$", t)]
    return (texts[0] if texts else "?"), " / ".join(body)


def emit(obj):
    print(json.dumps(obj, ensure_ascii=False), flush=True)


def main():
    after = int(sys.argv[sys.argv.index("--after") + 1]) if "--after" in sys.argv else -1
    if after < 0:
        after = max((i for i, _ in fetch(0)), default=0)
    emit({"t": "start", "last": after})
    while True:
        try:
            for nid, payload in fetch(after):
                after = max(after, nid)
                msg = parse(payload)
                if msg:
                    emit({"t": "msg", "id": nid, "sender": msg[0], "text": msg[1]})
            emit({"t": "idle", "sec": round(idle_seconds()), "last": after})
        except Exception as e:  # keep watching through transient DB locks
            emit({"t": "error", "text": f"{type(e).__name__}: {e}"})
            time.sleep(10)
        time.sleep(TICK)


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
