# WA delta

Replies to WhatsApp Desktop (Windows) messages while you are away from the computer.

A small Python watcher reads the Windows notification database for WhatsApp message toasts and
reports how long the mouse and keyboard have been idle. When a contact writes and the PC has been
idle long enough, the plugin drafts a reply with the session's own model, opens that chat by name,
waits a random "seen → typing" delay, types the reply character by character (so the contact sees
"typing…"), sends it and minimizes WhatsApp again.

## Install

At the prompt of a Claude Code terminal session:

```
/plugin install wa-delta --marketplace kinleee/wa-delta
```

Answer `y` to add the marketplace, then pick a scope (user scope loads it in every session).

From a shell:

```
claude plugin install wa-delta --marketplace kinleee/wa-delta
```

In the desktop app: click + next to the prompt box, then Plugins, Add marketplace with
`kinleee/wa-delta`, then Add plugin.

## Use

Open the panel with `/wa-delta`; `/wa-delta on` and `/wa-delta off` switch it. It starts switched off.

- **Template**: the default template applies to everyone; pick a contact to override any setting
  below for that person alone.
- **Reply style**: emoji, punctuation, humour, warm, corporate, irritated, expert, long, short;
  none selected is the default mode; a custom prompt overrides them.
- **Timing**: idle seconds, random extra delay, seen-to-typing delay, typing speed or paste,
  active hours.
- **Permissions** per contact: off, notify only, approve each reply, or reply freely. Risky
  messages (facts, commitments, money, "are you a bot?") can always come back to you; a daily
  cap per contact.
- **Telegram approvals**: create a bot with @BotFather, send it /start, paste the token in the
  panel. Replies that need your decision arrive there with Send / Skip buttons, or reply with your
  own text. Only the chat that bound the bot is listened to. The token is kept in Claude Code's
  local plugin store, not in this repository.

Needs Windows, WhatsApp Desktop, Python 3 on PATH and the WhatsApp window maximized on its
monitor when it acts. Automating WhatsApp is against its terms of service; use at your own risk.
