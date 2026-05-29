<!-- @format -->

# Media Saver. Save Videos, Photos, Reels from Facebook, Instagram, TikTok, Twitter and Snapchat no watermark

[![Rust](https://img.shields.io/badge/Rust-1.89+-orange?logo=rust)](https://www.rust-lang.org/) [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE) ![Views](https://komarev.com/ghpvc/?username=devfemibadmus&repo=mediasaver&color=blue) [![Get it on Google Play](https://img.shields.io/badge/Get%20it%20on-Google%20Play-3DDC84?logo=googleplay&logoColor=white)](https://play.google.com/store/apps/details?id=com.blackstackhub.mediasaver) [![Download on the App Store](https://img.shields.io/badge/Download%20on-the%20App%20Store-0D96F6?logo=appstore&logoColor=white)](https://www.apple.com/app-store/)

feature graphic from [hotpot.io](https://hotpot.io)
[![Feature Graphic](media/JN5MqT0rsNOi_1024_500.png?raw=true)](https://play.google.com/store/apps/details?id=com.blackstackhub.mediasaver)

## Screenshots


| Start                                              | Policy                                              |
| -------------------------------------------------- | --------------------------------------------------- |
| ![Start](media/Screenshot_1767164144.png?raw=true) | ![Policy](media/Screenshot_1767164157.png?raw=true) |


| Home                                              | Preview                                              |
| ------------------------------------------------- | ---------------------------------------------------- |
| ![Home](media/Screenshot_1767164244.png?raw=true) | ![Preview](media/Screenshot_1767164256.png?raw=true) |


| Preview                                              | Preview                                              |
| ---------------------------------------------------- | ---------------------------------------------------- |
| ![Preview](media/Screenshot_1767164382.png?raw=true) | ![Preview](media/Screenshot_1767164492.png?raw=true) |


| History                                              | Feedback                                              |
| ---------------------------------------------------- | ----------------------------------------------------- |
| ![History](media/Screenshot_1767164269.png?raw=true) | ![Feedback](media/Screenshot_1767164501.png?raw=true) |

## API Usage


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


| Platform  | Status | Example URL Pattern                                  |
| --------- | ------ | ---------------------------------------------------- |
| Facebook  | OK     | `facebook.com/...`, `fb.watch/...`                   |
| Instagram | OK     | `instagram.com/p/...`, `instagram.com/reel/...`      |
| TikTok    | OK     | `tiktok.com/...`, `vm.tiktok.com/...`                |
| Snapchat  | OK     | `snapchat.com/t/...`                                 |
| Twitter/X | OK     | `twitter.com/.../status/...`, `x.com/.../status/...` |
| NASA      | OK     | `svs.gsfc.nasa.gov/12345`, `images.nasa.gov/details/...` |

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

NASA Image Library:

```bash
curl "https://mediasaver.link/api/?url=https://images.nasa.gov/details/iss074e0609033"
```

## Disclaimer

This tool is for educational purposes only. Use it responsibly and respect platform terms of service.

## License

MIT License. See [LICENSE](LICENSE).
