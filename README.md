# Pooyan 0.02

**Languages:** فارسی | English | 中文 | Русский

---

## فارسی

### معرفی
**Pooyan 0.02** یک اسکریپت Bash برای راه‌اندازی و مدیریت خودکار Xray به‌همراه Cloudflare Tunnel است. این پروژه برای ساده‌سازی نصب، مدیریت سرویس، و تولید لینک‌های اتصال طراحی شده است.

### قابلیت‌ها
- پشتیبانی از چند زبان: **پارسی / English / 中文 / Русский**
- دو حالت اجرا:
  - **Quick Mode** برای ساخت لینک موقت
  - **Service Mode** برای نصب پایدارتر روی سیستم
- پشتیبانی از پروتکل‌های **VMess** و **VLESS**
- پشتیبانی از **IPv4** و **IPv6**
- پشتیبانی از چند توزیع لینوکس:
  - Debian
  - Ubuntu
  - CentOS
  - Fedora
  - Alpine
- منوی مدیریت سرویس پس از نصب

### نصب آسان
لینک خام فایل نصب را در مخزن خودت بگذار و این دستور را داخل README قرار بده:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PooyanGhorbani/Pooyan/main/pooyan.sh)
```

اگر خواستی فایل اول دانلود شود و بعد اجرا شود:

```bash
curl -fsSL https://raw.githubusercontent.com/PooyanGhorbani/Pooyan/main/pooyan.sh -o pooyan.sh && chmod +x pooyan.sh && bash pooyan.sh
```

**نکته:** فقط `PooyanGhorbani` و `Pooyan` را با آدرس واقعی گیت‌هاب خودت عوض کن.

### پیش‌نیازها
- سیستم‌عامل لینوکس
- دسترسی root
- ابزارهای پایه مثل `curl` و `unzip`
- برای حالت نصب سرویس: دامنه متصل به Cloudflare

### اجرای اسکریپت
```bash
chmod +x pooyan.sh
./pooyan.sh
```

### گزینه‌های منو
- **1. Quick Mode**: اجرای موقت
- **2. Install Service**: نصب سرویس
- **3. Uninstall Service**: حذف سرویس
- **4. Clear Cache**: پاک کردن فایل‌های موقت
- **5. Manage Service**: مدیریت سرویس نصب‌شده
- **0. Exit**: خروج

### مسیرهای اصلی
- مسیر نصب: `/opt/pooyan`
- فرمان مدیریت: `pooyan`
- فایل لینک‌ها: `/opt/pooyan/v2ray.txt`

### نکات مهم
- در **Quick Mode**، لینک ایجادشده ممکن است بعد از ریبوت سرور یا اجرای دوباره اسکریپت از کار بیفتد.
- در **Service Mode**، برای استفاده از دامنه اختصاصی باید دامنه شما در Cloudflare مدیریت شود.
- این پروژه باید فقط مطابق قوانین، شرایط سرویس Cloudflare، و مسئولیت شخصی شما استفاده شود.

### سلب مسئولیت
این پروژه صرفاً برای اهداف آموزشی، آزمایشی، و مدیریتی ارائه شده است. مسئولیت استفاده از آن بر عهده کاربر است.

---

## English

### Overview
**Pooyan 0.02** is a Bash script for automating Xray setup and management together with Cloudflare Tunnel. It is designed to simplify installation, service management, and connection link generation.

### Features
- Multilingual interface: **Persian / English / 中文 / Русский**
- Two operating modes:
  - **Quick Mode** for temporary links
  - **Service Mode** for a more persistent setup
- Supports **VMess** and **VLESS**
- Supports **IPv4** and **IPv6**
- Supports multiple Linux distributions:
  - Debian
  - Ubuntu
  - CentOS
  - Fedora
  - Alpine
- Management menu for installed service

### Easy Install
Add this one-line installer to your GitHub README after uploading the script to your repository:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PooyanGhorbani/Pooyan/main/pooyan.sh)
```

If you prefer to download first and run after that:

```bash
curl -fsSL https://raw.githubusercontent.com/PooyanGhorbani/Pooyan/main/pooyan.sh -o pooyan.sh && chmod +x pooyan.sh && bash pooyan.sh
```

**Note:** replace `PooyanGhorbani` and `Pooyan` with your real GitHub path.

### Requirements
- Linux server
- Root access
- Basic tools such as `curl` and `unzip`
- For Service Mode: a domain managed in Cloudflare

### Run
```bash
chmod +x pooyan.sh
./pooyan.sh
```

### Menu Options
- **1. Quick Mode**: temporary run
- **2. Install Service**: install service
- **3. Uninstall Service**: remove service
- **4. Clear Cache**: remove temporary files
- **5. Manage Service**: manage installed service
- **0. Exit**: exit

### Main Paths
- Install path: `/opt/pooyan`
- Management command: `pooyan`
- Generated links file: `/opt/pooyan/v2ray.txt`

### Important Notes
- In **Quick Mode**, generated links may stop working after a reboot or after rerunning the script.
- In **Service Mode**, your domain should be managed by Cloudflare if you want to use a custom domain.
- Use this project only in compliance with applicable laws, Cloudflare terms, and your own responsibility.

### Disclaimer
This project is provided for educational, testing, and administrative purposes. You are responsible for how you use it.

---

## 中文

### 介绍
**Pooyan 0.02** 是一个 Bash 脚本，用于自动化部署和管理 Xray 与 Cloudflare Tunnel。该项目旨在简化安装、服务管理以及连接链接生成。

### 功能特点
- 多语言界面：**پارسی / English / 中文 / Русский**
- 两种运行模式：
  - **Quick Mode**：生成临时链接
  - **Service Mode**：安装为更稳定的服务
- 支持 **VMess** 和 **VLESS**
- 支持 **IPv4** 和 **IPv6**
- 支持多个 Linux 发行版：
  - Debian
  - Ubuntu
  - CentOS
  - Fedora
  - Alpine
- 安装后可使用服务管理菜单

### 一键安装
把脚本上传到你的 GitHub 仓库后，可以在 README 中放这个安装命令：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PooyanGhorbani/Pooyan/main/pooyan.sh)
```

如果你更喜欢先下载再执行：

```bash
curl -fsSL https://raw.githubusercontent.com/PooyanGhorbani/Pooyan/main/pooyan.sh -o pooyan.sh && chmod +x pooyan.sh && bash pooyan.sh
```

**说明：** 请把 `PooyanGhorbani` 和 `Pooyan` 替换成你自己的 GitHub 路径。

### 运行要求
- Linux 系统
- Root 权限
- 基础工具，如 `curl` 和 `unzip`
- Service Mode 需要 Cloudflare 托管域名

### 运行方式
```bash
chmod +x pooyan.sh
./pooyan.sh
```

### 菜单选项
- **1. Quick Mode**：临时运行
- **2. Install Service**：安装服务
- **3. Uninstall Service**：卸载服务
- **4. Clear Cache**：清理临时文件
- **5. Manage Service**：管理已安装服务
- **0. Exit**：退出

### 主要路径
- 安装目录：`/opt/pooyan`
- 管理命令：`pooyan`
- 链接文件：`/opt/pooyan/v2ray.txt`

### 重要说明
- 在 **Quick Mode** 下，生成的链接在服务器重启或脚本重新运行后可能失效。
- 在 **Service Mode** 下，如需使用自定义域名，域名应由 Cloudflare 托管。
- 请仅在遵守当地法律、Cloudflare 服务条款和个人责任的前提下使用本项目。

### 免责声明
本项目仅用于学习、测试和管理目的。使用方式及后果由用户自行负责。

---

## Русский

### Описание
**Pooyan 0.02** — это Bash-скрипт для автоматической настройки и управления Xray вместе с Cloudflare Tunnel. Проект создан для упрощения установки, управления сервисом и генерации ссылок подключения.

### Возможности
- Многоязычный интерфейс: **فارسی / English / 中文 / Русский**
- Два режима работы:
  - **Quick Mode** для временных ссылок
  - **Service Mode** для более постоянной установки
- Поддержка **VMess** и **VLESS**
- Поддержка **IPv4** и **IPv6**
- Поддержка нескольких дистрибутивов Linux:
  - Debian
  - Ubuntu
  - CentOS
  - Fedora
  - Alpine
- Меню управления установленным сервисом

### Быстрая установка
После загрузки скрипта в GitHub-репозиторий можно добавить в README такую команду установки:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PooyanGhorbani/Pooyan/main/pooyan.sh)
```

Если хочешь сначала скачать файл, а потом запустить:

```bash
curl -fsSL https://raw.githubusercontent.com/PooyanGhorbani/Pooyan/main/pooyan.sh -o pooyan.sh && chmod +x pooyan.sh && bash pooyan.sh
```

**Примечание:** замени `PooyanGhorbani` и `Pooyan` на свой реальный путь GitHub.

### Требования
- Linux-сервер
- Root-доступ
- Базовые инструменты, такие как `curl` и `unzip`
- Для Service Mode: домен под управлением Cloudflare

### Запуск
```bash
chmod +x pooyan.sh
./pooyan.sh
```

### Пункты меню
- **1. Quick Mode**: временный запуск
- **2. Install Service**: установка сервиса
- **3. Uninstall Service**: удаление сервиса
- **4. Clear Cache**: очистка временных файлов
- **5. Manage Service**: управление установленным сервисом
- **0. Exit**: выход

### Основные пути
- Путь установки: `/opt/pooyan`
- Команда управления: `pooyan`
- Файл со ссылками: `/opt/pooyan/v2ray.txt`

### Важные замечания
- В **Quick Mode** сгенерированные ссылки могут перестать работать после перезагрузки сервера или повторного запуска скрипта.
- В **Service Mode** для собственного домена домен должен обслуживаться через Cloudflare.
- Используйте проект только в рамках закона, условий Cloudflare и под свою ответственность.

### Отказ от ответственности
Проект предоставляется в образовательных, тестовых и административных целях. Пользователь несёт полную ответственность за способ использования.

---

## License
Choose a license that matches your intended use before publishing the repository.
