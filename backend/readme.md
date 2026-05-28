<!-- @format -->

# MEDIASCRAPER API

[![Rust](https://img.shields.io/badge/Rust-1.89+-orange?logo=rust)](https://www.rust-lang.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Google Play](https://img.shields.io/badge/Google%20Play-Download-brightgreen?logo=google-play)](https://play.google.com/store/apps/details?id=com.blackstackhub.mediasaver)
![Views](https://komarev.com/ghpvc/?username=devfemibadmus&repo=mediascraper&color=blue)

## Overview

**MEDIASCRAPER API** is a high-performance REST API built with Rust and Actix Web for extracting media content such as videos, images, and audio from supported platforms.

## Features

- **Multi-platform support**: Facebook, Instagram, TikTok, Snapchat, Twitter (X), and NASA SVS
- **High performance**: async scraping with Rust and Actix Web
- **Clean API**: consistent JSON responses across platforms
- **Error handling**: readable failure messages with appropriate HTTP status codes

## Quick Start

```bash
git clone https://github.com/yourusername/mediascraper.git
cd mediascraper
cargo build --release
cargo run
```

Server runs at `http://localhost:8080`.

## API Usage

Endpoint:

```text
GET or POST /api/
```

GET request:

```bash
curl "https://mediasaver.link/api/?url=YOUR_MEDIA_URL"
```

POST request:

```bash
curl -X POST https://mediasaver.link/api/ \
  -H "Content-Type: application/json" \
  -d '{"url":"YOUR_MEDIA_URL"}'
```

## Supported Platforms

| Platform | Status | Example URL Pattern |
| --- | --- | --- |
| Facebook | OK | `facebook.com/...`, `fb.watch/...` |
| Instagram | OK | `instagram.com/p/...`, `instagram.com/reel/...` |
| TikTok | OK | `tiktok.com/...`, `vm.tiktok.com/...` |
| Snapchat | OK | `snapchat.com/t/...` |
| Twitter/X | OK | `twitter.com/.../status/...`, `x.com/.../status/...` |
| NASA SVS | OK | `svs.gsfc.nasa.gov/12345`, `...#media_group_67890` |

## Response Format

Success:

```json
{
  "data": ["https://media-url-1.mp4", "https://media-url-2.jpg"],
  "total": 2,
  "platform": "platform_name"
}
```

Error:

```json
{
  "error": true,
  "message": "Error description",
  "error_message": "Error description"
}
```

## Examples

TikTok:

```bash
curl "https://mediasaver.link/api/?url=https://vm.tiktok.com/ZSHK8GLq32Kjh-qQ9X4/"
```

Instagram:

```bash
curl "https://mediasaver.link/api/?url=https://www.instagram.com/reel/DHm7knuzl1D"
```

Facebook:

```bash
curl "https://mediasaver.link/api/?url=https://www.facebook.com/share/v/qCRH3vKk2FbAEAUP/"
```

Snapchat:

```bash
curl "https://mediasaver.link/api/?url=https://snapchat.com/t/GJbX4HdO"
```

Twitter:

```bash
curl "https://mediasaver.link/api/?url=https://x.com/username/status/1234567890"
```

NASA SVS:

```bash
curl "https://mediasaver.link/api/?url=https://svs.gsfc.nasa.gov/31373/#media_group_379948"
```

## Project Structure

```text
mediascraper/
|-- src/
|   |-- main.rs
|   `-- platforms/
|       |-- mod.rs
|       |-- facebook.rs
|       |-- instagram.rs
|       |-- nasa.rs
|       |-- snapchat.rs
|       |-- tiktok.rs
|       `-- twitter.rs
|-- Cargo.toml
`-- website/
    |-- static/
    `-- *.html
```

## Dependencies

Key dependencies in `Cargo.toml`:

- `actix-web` for the HTTP server
- `reqwest` for outbound requests
- `scraper` for HTML parsing
- `serde_json` for JSON handling
- `regex` for URL validation
- `tera` for template rendering

## Testing

Run all tests:

```bash
cargo test
```

Run a specific platform test:

```bash
cargo test facebook -- --nocapture
cargo test nasa -- --nocapture
```

## Disclaimer

This tool is for educational purposes only. Use it responsibly and respect platform terms of service.

## License

MIT License. See [LICENSE](LICENSE).
