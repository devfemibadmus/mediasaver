use actix_web::{HttpResponse, http::StatusCode};
use regex::Regex;
use reqwest::Client;
use reqwest::header::{ACCEPT, ACCEPT_LANGUAGE, HeaderMap, HeaderValue, USER_AGENT};
use scraper::{Html, Selector};
use serde_json::{Value, json};
use std::collections::HashSet;

pub struct Facebook {
    url: String,
    client: Client,
}

impl Facebook {
    pub fn new(client: Client, url: &str) -> Self {
        Self {
            url: url.to_string(),
            client,
        }
    }

    fn headers() -> HeaderMap {
        let mut headers = HeaderMap::new();

        headers.insert(ACCEPT, HeaderValue::from_static(
            "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
        ));
        headers.insert(ACCEPT_LANGUAGE, HeaderValue::from_static("en-US,en;q=0.9"));
        headers.insert(USER_AGENT, HeaderValue::from_static(
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
        ));
        headers.insert("Dnt", HeaderValue::from_static("1"));
        headers.insert("Dpr", HeaderValue::from_static("1.3125"));
        headers.insert("Priority", HeaderValue::from_static("u=0, i"));
        headers.insert(
            "Sec-Ch-Prefers-Color-Scheme",
            HeaderValue::from_static("dark"),
        );
        headers.insert(
            "Sec-Ch-Ua",
            HeaderValue::from_static(
                "\"Chromium\";v=\"124\", \"Google Chrome\";v=\"124\", \"Not-A.Brand\";v=\"99\"",
            ),
        );
        headers.insert("Sec-Ch-Ua-Full-Version-List", HeaderValue::from_static("\"Chromium\";v=\"124.0.6367.156\", \"Google Chrome\";v=\"124.0.6367.156\", \"Not-A.Brand\";v=\"99.0.0.0\""));
        headers.insert("Sec-Ch-Ua-Mobile", HeaderValue::from_static("?0"));
        headers.insert("Sec-Ch-Ua-Model", HeaderValue::from_static("\"\""));
        headers.insert(
            "Sec-Ch-Ua-Platform",
            HeaderValue::from_static("\"Windows\""),
        );
        headers.insert(
            "Sec-Ch-Ua-Platform-Version",
            HeaderValue::from_static("\"15.0.0\""),
        );
        headers.insert("Sec-Fetch-Dest", HeaderValue::from_static("document"));
        headers.insert("Sec-Fetch-Mode", HeaderValue::from_static("navigate"));
        headers.insert("Sec-Fetch-Site", HeaderValue::from_static("none"));
        headers.insert("Sec-Fetch-User", HeaderValue::from_static("?1"));
        headers.insert("Upgrade-Insecure-Requests", HeaderValue::from_static("1"));
        headers.insert("Viewport-Width", HeaderValue::from_static("1463"));

        headers
    }

    async fn get(&self, url: &str) -> reqwest::Result<reqwest::Response> {
        self.client.get(url).headers(Self::headers()).send().await
    }

    fn get_nested_value<'a>(data: &'a Value, key: &str) -> Option<&'a Value> {
        match data {
            Value::Object(map) => {
                if let Some(v) = map.get(key) {
                    return Some(v);
                }
                for v in map.values() {
                    if let Some(res) = Self::get_nested_value(v, key) {
                        return Some(res);
                    }
                }
                None
            }
            Value::Array(arr) => {
                for v in arr {
                    if let Some(res) = Self::get_nested_value(v, key) {
                        return Some(res);
                    }
                }
                None
            }
            _ => None,
        }
    }

    fn decode_embedded_url(value: &str) -> String {
        value
            .replace("\\/", "/")
            .replace("\\u0025", "%")
            .replace("\\u0026", "&")
            .replace("\\u003d", "=")
            .replace("\\u003D", "=")
            .replace("\\u003f", "?")
            .replace("\\u003F", "?")
            .replace("\\u002f", "/")
            .replace("\\u002F", "/")
            .replace("&amp;", "&")
    }

    fn collect_embedded_media_urls(html: &str) -> Vec<Value> {
        let normalized = html.replace("&quot;", "\"");
        let fields = [
            "browser_native_hd_url",
            "browser_native_sd_url",
            "playable_url_quality_hd",
            "playable_url",
            "hd_src",
            "sd_src",
            "base_url",
        ];
        let mut out = Vec::new();
        let mut seen = HashSet::new();

        for field in fields {
            let pattern = format!(r#""{}"\s*:\s*"([^"]+)""#, regex::escape(field));
            let re = match Regex::new(&pattern) {
                Ok(re) => re,
                Err(_) => continue,
            };

            for capture in re.captures_iter(&normalized) {
                let Some(raw) = capture.get(1).map(|m| m.as_str()) else {
                    continue;
                };
                let url = Self::decode_embedded_url(raw);
                let lower = url.to_lowercase();
                let looks_like_media = url.starts_with("http")
                    && (lower.contains(".mp4")
                        || lower.contains("video")
                        || lower.contains("fbcdn")
                        || lower.contains("fbsbx"));

                if looks_like_media && seen.insert(url.clone()) {
                    out.push(json!(url));
                }
            }
        }

        out
    }

    fn collect_combined_media(data: &Value) -> Vec<Value> {
        let fields = [
            "browser_native_hd_url",
            "browser_native_sd_url",
            "playable_url_quality_hd",
            "playable_url",
            "hd_src",
            "sd_src",
        ];
        let mut out = Vec::new();
        let mut seen = HashSet::new();

        for field in fields {
            if let Some(url) = Self::get_nested_value(data, field).and_then(|value| value.as_str())
            {
                let url = Self::decode_embedded_url(url);
                if !url.is_empty() && seen.insert(url.clone()) {
                    out.push(json!(url));
                }
            }
        }

        out
    }

    async fn fetch_json(&mut self) -> Result<Value, String> {
        if self.url.contains("fb.watch") || self.url.contains("/watch/?v") {
            if let Ok(resp) = self.get(&self.url).await {
                if let Some(video_id) = resp
                    .url()
                    .path_segments()
                    .and_then(|segments| segments.skip_while(|s| *s != "videos").nth(1))
                {
                    self.url = format!("https://www.facebook.com/reel/{}", video_id);
                } else {
                    return Err("video not found".into());
                }
            } else {
                return Err("video request failed".into());
            }
        }

        let resp = self
            .get(&self.url)
            .await
            .map_err(|e| format!("Request error: {}", e))?;
        if resp.status() != 200 {
            return Err(format!("Failed to fetch page: {}", resp.status()));
        }
        let text = resp
            .text()
            .await
            .map_err(|e| format!("Read body failed: {}", e))?;
        let document = Html::parse_document(&text);
        let script_sel = Selector::parse("script[type='application/json']").unwrap();
        let mut preferred_thumbnail: Option<Value> = None;
        let mut browser_native_hd_url: Option<Value> = None;
        let mut json_data: Option<Value> = None;

        for script in document.select(&script_sel) {
            let script_text = script.text().next().unwrap_or("").trim();
            if script_text.contains("preferred_thumbnail") && json_data.is_none() {
                let parsed: Value =
                    serde_json::from_str(&script_text).map_err(|_| "Invalid JSON")?;
                preferred_thumbnail =
                    Self::get_nested_value(&parsed, "preferred_thumbnail").cloned();
                browser_native_hd_url =
                    Self::get_nested_value(&parsed, "browser_native_hd_url").cloned();
                json_data = Some(parsed);
            }
        }

        for script in document.select(&script_sel) {
            let script_text = script.text().next().unwrap_or("").trim();
            let keywords = ["base_url", "total_comment_count"];
            if keywords.iter().all(|k| script_text.contains(k)) {
                let mut parsed: Value =
                    serde_json::from_str(&script_text).map_err(|_| "Invalid JSON")?;

                let mut data = Self::get_nested_value(&parsed, "data").cloned();
                let owner = Self::get_nested_value(&parsed, "owner_as_page")
                    .cloned()
                    .or_else(|| {
                        data.as_ref()
                            .and_then(|d| Self::get_nested_value(d, "owner").cloned())
                    });

                if let Some(d) = data.as_mut() {
                    if d.get("title").and_then(|t| t.get("text")).is_none() {
                        if let Some(message) = d.get("message").and_then(|m| m.get("text")) {
                            d["title"] = json!({ "text": message });
                        }
                    }
                }

                if browser_native_hd_url.is_none() {
                    let reps = Self::get_nested_value(&parsed, "representations")
                        .and_then(|r| r.as_array().cloned())
                        .unwrap_or_default();
                    let mut deaf_media = json!({});
                    for rep in reps {
                        if let Some(mime) = rep.get("mime_type").and_then(|m| m.as_str()) {
                            if mime.to_lowercase().contains("video") {
                                deaf_media["video_url"] =
                                    rep.get("base_url").cloned().unwrap_or(json!("N/A"));
                            } else if mime.to_lowercase().contains("audio") {
                                deaf_media["audio_url"] =
                                    rep.get("base_url").cloned().unwrap_or(json!("N/A"));
                            }
                        }
                    }
                    parsed["deaf_media"] = deaf_media;
                }

                parsed["data"] = data.unwrap_or(json!({}));
                parsed["owner"] = owner.unwrap_or(json!({}));
                parsed["platform"] = json!("facebook");
                parsed["preferred_thumbnail"] = preferred_thumbnail.unwrap_or(json!({}));

                return Ok(parsed);
            }
        }

        let fallback_media = Self::collect_embedded_media_urls(&text);
        if !fallback_media.is_empty() {
            return Ok(json!({
                "fallback_media": fallback_media,
                "platform": "facebook"
            }));
        }

        Err("Video not visible. Open it in Reels and share the link again.".into())
    }

    fn err(&self, message: &str, error_message: &str) -> Value {
        json!({ "error": true, "message": message, "error_message": error_message })
    }

    pub async fn get_data(&mut self) -> HttpResponse {
        let data = match self.fetch_json().await {
            Ok(d) => d,
            Err(e) => {
                return HttpResponse::build(StatusCode::BAD_GATEWAY).json(self.err(&e, &e));
            }
        };

        let mut out = Vec::new();

        let combined_media = Self::collect_combined_media(&data);
        let representations = Self::get_nested_value(&data, "representations").cloned();
        let preferred_thumbnail = Self::get_nested_value(&data, "preferred_thumbnail").cloned();

        if let Some(media) = data
            .get("fallback_media")
            .and_then(|media| media.as_array())
        {
            for url in media {
                if !out.contains(url) {
                    out.push(url.clone());
                }
            }
        }

        for url in combined_media {
            if !out.contains(&url) {
                out.push(url);
            }
        }

        if out.is_empty() {
            if let Some(reps) = representations.and_then(|r| r.as_array().cloned()) {
                let best_video = reps
                    .iter()
                    .filter(|r| {
                        r.get("mime_type")
                            .and_then(|m| m.as_str())
                            .unwrap_or("")
                            .contains("video")
                    })
                    .max_by_key(|r| r.get("bandwidth").and_then(|b| b.as_u64()).unwrap_or(0));
                let best_audio = reps
                    .iter()
                    .filter(|r| {
                        r.get("mime_type")
                            .and_then(|m| m.as_str())
                            .unwrap_or("")
                            .contains("audio")
                    })
                    .max_by_key(|r| r.get("bandwidth").and_then(|b| b.as_u64()).unwrap_or(0));

                if let Some(v) = best_video {
                    if let Some(url) = v.get("base_url").cloned() {
                        out.push(url);
                    }
                }
                if let Some(_) = best_audio {
                    if let Some(url) = best_audio
                        .and_then(|a| a.get("base_url"))
                        .and_then(|v| v.as_str())
                    {
                        out.push(format!("audio==={}", url).into());
                    }
                }
            }
        }

        if let Some(thumb) = preferred_thumbnail
            .as_ref()
            .and_then(|p| p.get("image"))
            .and_then(|i| i.get("uri"))
            .cloned()
        {
            out.push(thumb);
        }

        let result = json!({
            "data": out,
            "total": out.len(),
            "platform": "facebook"
        });

        HttpResponse::Ok().json(result)
    }
}

#[tokio::test]
async fn facebook() {
    let client = reqwest::Client::new();
    let mut scraper = Facebook::new(client, "https://www.facebook.com/share/r/1HG3ksoqj8/?");
    let response = scraper.get_data().await;
    let status = response.status();
    println!("Status: {}", status);
    let body_bytes = actix_web::body::to_bytes(response.into_body())
        .await
        .unwrap();
    let body_str = String::from_utf8(body_bytes.to_vec()).unwrap();
    println!("Body: {}", body_str);
    assert_eq!(status, StatusCode::OK);
}
