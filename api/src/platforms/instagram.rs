use actix_web::{HttpResponse, http::StatusCode};
use reqwest::Client;
use reqwest::header::{ACCEPT, ACCEPT_LANGUAGE, HeaderMap, HeaderValue, USER_AGENT};
use serde_json::{Value, json};
use scraper::{Html, Selector};

pub struct Instagram {
    client: Client,
    url: String,
}

impl Instagram {
    pub fn new(client: Client, url: String) -> Self {
        Self { client, url }
    }

    fn headers() -> HeaderMap {
        let mut headers = HeaderMap::new();
        headers.insert(
            ACCEPT,
            HeaderValue::from_static("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"),
        );
        headers.insert(ACCEPT_LANGUAGE, HeaderValue::from_static("en-US,en;q=0.5"));
        headers.insert(
            USER_AGENT,
            HeaderValue::from_static(
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36",
            ),
        );
        headers
    }

    fn extract_shortcode(url: &str) -> Option<&str> {
        url.split("/reel/")
            .nth(1)
            .or_else(|| url.split("/p/").nth(1))
            .or_else(|| url.split("/tv/").nth(1))
            .and_then(|s| s.split('/').next())
            .and_then(|s| s.split('?').next())
    }

    fn is_cdn_media_url(url: &str) -> bool {
        (url.contains("cdninstagram.com") || url.contains("fbcdn.net"))
            && !url.contains("static.cdninstagram.com")
    }

    async fn fetch_media_direct(&self, shortcode: &str) -> Result<Vec<String>, String> {
        let url = format!("https://www.instagram.com/p/{}/media/?size=l", shortcode);

        let resp = self
            .client
            .get(&url)
            .headers(Self::headers())
            .send()
            .await
            .map_err(|e| format!("Direct media request failed: {}", e))?;

        let final_url = resp.url().to_string();

        if Self::is_cdn_media_url(&final_url) {
            let clean = final_url.split('?').next().unwrap_or(&final_url).to_string();
            Ok(vec![clean])
        } else {
            Err("Direct media endpoint did not redirect to a CDN URL".to_string())
        }
    }

    async fn fetch_page_media(&self, shortcode: &str) -> Result<Vec<String>, String> {
        let page_url = format!("https://www.instagram.com/p/{}/", shortcode);

        let resp = self
            .client
            .get(&page_url)
            .headers(Self::headers())
            .send()
            .await
            .map_err(|e| format!("Page request failed: {}", e))?;

        if !resp.status().is_success() {
            return Err(format!("Page returned status {}", resp.status().as_u16()));
        }

        let html = resp
            .text()
            .await
            .map_err(|e| format!("Failed to read page: {}", e))?;

        let mut results = Vec::new();
        let document = Html::parse_document(&html);

        let og_video_secure = Selector::parse("meta[property=\"og:video:secure_url\"]").unwrap();
        for el in document.select(&og_video_secure) {
            if let Some(c) = el.value().attr("content") {
                if !c.is_empty() {
                    results.push(c.to_string());
                }
            }
        }

        let og_video = Selector::parse("meta[property=\"og:video\"]").unwrap();
        for el in document.select(&og_video) {
            if let Some(c) = el.value().attr("content") {
                if !c.is_empty() && !results.contains(&c.to_string()) {
                    results.push(c.to_string());
                }
            }
        }

        let og_image = Selector::parse("meta[property=\"og:image\"]").unwrap();
        for el in document.select(&og_image) {
            if let Some(c) = el.value().attr("content") {
                if !c.is_empty() && !results.contains(&c.to_string()) {
                    results.push(c.to_string());
                }
            }
        }

        let ld_json = Selector::parse("script[type=\"application/ld+json\"]").unwrap();
        for el in document.select(&ld_json) {
            let text: String = el.text().collect();
            if let Ok(parsed) = serde_json::from_str::<Value>(&text) {
                if let Some(img) = parsed.get("image") {
                    match img {
                        Value::String(s) => {
                            if !results.contains(s) {
                                results.push(s.clone());
                            }
                        }
                        Value::Array(arr) => {
                            for v in arr {
                                if let Some(s) = v.as_str() {
                                    if !results.contains(&s.to_string()) {
                                        results.push(s.to_string());
                                    }
                                }
                            }
                        }
                        _ => {}
                    }
                }
                if let Some(vid_url) = parsed
                    .get("video")
                    .and_then(|v| v.get("contentUrl"))
                    .and_then(|s| s.as_str())
                {
                    if !results.contains(&vid_url.to_string()) {
                        results.push(vid_url.to_string());
                    }
                }
            }
        }

        if results.is_empty() {
            Err("No media found on page".to_string())
        } else {
            Ok(results)
        }
    }

    pub async fn get_data(&self) -> HttpResponse {
        let shortcode = match Self::extract_shortcode(&self.url) {
            Some(id) => id.to_string(),
            None => {
                return HttpResponse::NotFound()
                    .json(json!({ "error_message": "Could not extract post ID from URL" }));
            }
        };

        let results = match self.fetch_media_direct(&shortcode).await {
            Ok(urls) => urls,
            Err(_) => match self.fetch_page_media(&shortcode).await {
                Ok(urls) => urls,
                Err(e) => {
                    return HttpResponse::build(StatusCode::BAD_GATEWAY)
                        .json(json!({ "error_message": e }));
                }
            },
        };

        HttpResponse::Ok().json(json!({
            "data": results,
            "total": results.len(),
            "platform": "instagram"
        }))
    }
}

#[tokio::test]
async fn instagram() {
    let client = reqwest::Client::builder()
        .redirect(reqwest::redirect::Policy::limited(5))
        .build()
        .unwrap();
    let scraper = Instagram::new(
        client,
        "https://www.instagram.com/p/DajR8O7PHb3/".to_string(),
    );
    let response = scraper.get_data().await;
    let status = response.status();
    println!("Status: {}", status);
    let body_bytes = actix_web::body::to_bytes(response.into_body())
        .await
        .unwrap();
    let body_str = String::from_utf8(body_bytes.to_vec()).unwrap();
    println!("Body: {}", body_str);
    assert_eq!(status, StatusCode::OK);
    let v: Value = serde_json::from_str(&body_str).unwrap();
    let url = v["data"][0].as_str().unwrap();
    assert!(
        url.contains("fbcdn.net") || url.contains("cdninstagram.com"),
        "Expected CDN URL, got: {}",
        url
    );
}
