# Pooyan 0.07 — China Recommended Edition

## فارسی

این نسخه برای استفاده روی VPS و کاربر داخل چین آماده شده است.

### بهترین انتخاب برای اکثر کاربران چین

گزینه 1:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PooyanGhorbani/Pooyan/main/pooyan.sh)
```

بعد از اجرا گزینه زیر را بزن:

```text
1) China Recommended - VLESS + Cloudflare Tunnel + service + BBR
```

این حالت:

- Xray را نصب می‌کند
- cloudflared را نصب می‌کند
- VLESS + WebSocket می‌سازد
- Cloudflare Tunnel را به دامنه تو وصل می‌کند
- سرویس systemd می‌سازد تا بعد از ریبوت خودکار بالا بیاید
- BBR را فعال می‌کند
- لینک‌های 443، 2053، 2083، 2087، 2096، 8443 و پورت‌های HTTP سازگار با Cloudflare را می‌سازد
- فایل لینک‌ها را در این مسیر ذخیره می‌کند:

```bash
/root/v2ray.txt
/opt/pooyan/v2ray.txt
```

### حالت حرفه‌ای برای VPS خیلی خوب

اگر VPS خوب با مسیر CN2 GIA / CMI / AS9929 داری، گزینه 2 را تست کن:

```text
2) Advanced - VLESS + REALITY + Vision direct
```

این حالت Cloudflare Tunnel ندارد و مستقیم روی IP سرور کار می‌کند. برای سرعت خام ممکن است بهتر باشد، ولی به کیفیت مسیر VPS خیلی وابسته است.

### مدیریت بعد از نصب

```bash
pooyan
```

از این منو می‌توانی سرویس‌ها را روشن/خاموش/ریستارت کنی، لینک‌ها را ببینی، لاگ‌ها را ببینی یا حذف کامل انجام بدهی.

### پیشنهاد من برای چین

اول گزینه 1 را نصب کن. اگر سرعت خوب نبود و VPS تو مسیر خیلی خوبی داشت، گزینه 2 یعنی Reality/Vision را جدا تست کن.

---

## English

Pooyan 0.07 is optimized for VPS use with users in China.

Recommended default:

```text
1) China Recommended - VLESS + Cloudflare Tunnel + service + BBR
```

Advanced direct mode for high-quality CN2/CMI/AS9929 VPS:

```text
2) Advanced - VLESS + REALITY + Vision direct
```

Manage after installation:

```bash
pooyan
```

Links are saved to:

```bash
/root/v2ray.txt
/opt/pooyan/v2ray.txt
```

---

## 中文

Pooyan 0.07 面向中国网络环境优化。

普通用户建议先使用：

```text
1) China Recommended - VLESS + Cloudflare Tunnel + service + BBR
```

如果你的 VPS 是高质量 CN2 GIA / CMI / AS9929 线路，可以测试：

```text
2) Advanced - VLESS + REALITY + Vision direct
```

安装后管理命令：

```bash
pooyan
```

节点链接保存位置：

```bash
/root/v2ray.txt
/opt/pooyan/v2ray.txt
```
