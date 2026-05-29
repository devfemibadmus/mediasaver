use actix_web::{HttpResponse, http::StatusCode};
use reqwest::Client;
use reqwest::header::{ACCEPT, ACCEPT_LANGUAGE, HeaderMap, HeaderValue, USER_AGENT};
use serde_json::{Value, json};
use std::collections::HashSet;
use tokio::time::{Duration, sleep};

pub struct Nasa {
    client: Client,
    url: String,
}

enum NasaSource {
    Svs {
        page_id: String,
        media_group_id: Option<u64>,
    },
    ImageLibrary {
        nasa_id: String,
    },
}

impl Nasa {
    pub fn new(client: Client, url: String) -> Self {
        Self { client, url }
    }

    fn headers() -> HeaderMap {
        let mut headers = HeaderMap::new();
        headers.insert(
            ACCEPT,
            HeaderValue::from_static("application/json, text/plain, */*"),
        );
        headers.insert(ACCEPT_LANGUAGE, HeaderValue::from_static("en-US,en;q=0.9"));
        headers.insert(
            USER_AGENT,
            HeaderValue::from_static(
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36",
            ),
        );
        headers
    }

    fn extract_source(url: &str) -> Option<NasaSource> {
        let parsed = reqwest::Url::parse(url).ok()?;
        let host = parsed.host_str()?.to_ascii_lowercase();
        let segments: Vec<&str> = parsed.path_segments()?.collect();

        if host == "images.nasa.gov" {
            let nasa_id = segments
                .windows(2)
                .find(|pair| pair[0] == "details")
                .map(|pair| pair[1].trim())
                .filter(|id| !id.is_empty())?
                .to_string();

            return Some(NasaSource::ImageLibrary { nasa_id });
        }

        if host == "svs.gsfc.nasa.gov" {
            let page_id = segments
                .iter()
                .find(|segment| {
                    !segment.is_empty() && segment.chars().all(|ch| ch.is_ascii_digit())
                })?
                .to_string();

            let media_group_id = parsed
                .fragment()
                .and_then(|fragment| fragment.strip_prefix("media_group_"))
                .and_then(|id| id.parse::<u64>().ok());

            return Some(NasaSource::Svs {
                page_id,
                media_group_id,
            });
        }

        None
    }

    async fn fetch_json_url(&self, api_url: &str) -> Result<Value, String> {
        let mut last_error = String::from("Unknown request error");

        for attempt in 0..3 {
            let request = self
                .client
                .get(api_url)
                .headers(Self::headers())
                .send()
                .await;

            match request {
                Ok(resp) => {
                    if !resp.status().is_success() {
                        return Err(format!("Failed to fetch NASA item: {}", resp.status()));
                    }

                    return resp
                        .json::<Value>()
                        .await
                        .map_err(|e| format!("JSON parse failed: {}", e));
                }
                Err(error) => {
                    last_error = format!("Request failed: {}", error);
                    if attempt < 2 {
                        sleep(Duration::from_millis(750)).await;
                    }
                }
            }
        }

        Err(last_error)
    }

    async fn fetch_svs_json(&self, page_id: &str) -> Result<Value, String> {
        let api_url = format!("https://svs.gsfc.nasa.gov/api/{}", page_id);
        self.fetch_json_url(&api_url).await
    }

    async fn fetch_image_library_json(&self, nasa_id: &str) -> Result<Value, String> {
        let api_url = format!("https://images-api.nasa.gov/asset/{}", nasa_id);
        self.fetch_json_url(&api_url).await
    }

    fn push_url(out: &mut Vec<Value>, seen: &mut HashSet<String>, value: &Value) {
        if let Some(url) = value.get("url").and_then(|v| v.as_str()) {
            let url = url.trim();
            if !url.is_empty() && seen.insert(url.to_string()) {
                out.push(json!(url));
            }
        }
    }

    fn push_href(out: &mut Vec<Value>, seen: &mut HashSet<String>, value: &Value) {
        if let Some(url) = value.get("href").and_then(|v| v.as_str()) {
            let url = url.trim();
            if !url.is_empty() && Self::is_media_asset(url) && seen.insert(url.to_string()) {
                out.push(json!(url));
            }
        }
    }

    fn is_media_asset(url: &str) -> bool {
        let path = url.split('?').next().unwrap_or(url).to_ascii_lowercase();
        [
            ".jpg", ".jpeg", ".png", ".gif", ".tif", ".tiff", ".mp4", ".mov", ".m4v", ".webm",
            ".mp3", ".wav", ".m4a",
        ]
        .iter()
        .any(|ext| path.ends_with(ext))
    }

    async fn get_svs_data(&self, page_id: &str, media_group_id: Option<u64>) -> HttpResponse {
        let data = match self.fetch_svs_json(page_id).await {
            Ok(data) => data,
            Err(error) => {
                return HttpResponse::build(StatusCode::BAD_GATEWAY)
                    .json(json!({ "error_message": error }));
            }
        };

        let media_groups = data
            .get("media_groups")
            .and_then(|groups| groups.as_array())
            .cloned()
            .unwrap_or_default();

        let selected_groups = if let Some(target_group) = media_group_id {
            let matching_groups: Vec<Value> = media_groups
                .into_iter()
                .filter(|group| group.get("id").and_then(|id| id.as_u64()) == Some(target_group))
                .collect();

            if matching_groups.is_empty() {
                return HttpResponse::NotFound()
                    .json(json!({ "error_message": "NASA media group not found" }));
            }

            matching_groups
        } else {
            media_groups
        };

        let mut out = Vec::new();
        let mut seen = HashSet::new();

        for group in selected_groups {
            if let Some(items) = group.get("items").and_then(|items| items.as_array()) {
                for item in items {
                    if let Some(instance) = item.get("instance") {
                        Self::push_url(&mut out, &mut seen, instance);
                    }
                }
            }
        }

        if out.is_empty() {
            if let Some(main_video) = data.get("main_video") {
                Self::push_url(&mut out, &mut seen, main_video);
            }
            if let Some(main_image) = data.get("main_image") {
                Self::push_url(&mut out, &mut seen, main_image);
            }
        }

        let result = json!({
            "data": out,
            "total": out.len(),
            "platform": "nasa"
        });

        HttpResponse::Ok().json(result)
    }

    async fn get_image_library_data(&self, nasa_id: &str) -> HttpResponse {
        let data = match self.fetch_image_library_json(nasa_id).await {
            Ok(data) => data,
            Err(error) => {
                return HttpResponse::build(StatusCode::BAD_GATEWAY)
                    .json(json!({ "error_message": error }));
            }
        };

        let mut out = Vec::new();
        let mut seen = HashSet::new();

        if let Some(items) = data
            .get("collection")
            .and_then(|collection| collection.get("items"))
            .and_then(|items| items.as_array())
        {
            for item in items {
                Self::push_href(&mut out, &mut seen, item);
            }
        }

        if out.is_empty() {
            return HttpResponse::NotFound()
                .json(json!({ "error_message": "NASA media asset not found" }));
        }

        HttpResponse::Ok().json(json!({
            "data": out,
            "total": out.len(),
            "platform": "nasa"
        }))
    }

    pub async fn get_data(&self) -> HttpResponse {
        match Self::extract_source(&self.url) {
            Some(NasaSource::Svs {
                page_id,
                media_group_id,
            }) => self.get_svs_data(&page_id, media_group_id).await,
            Some(NasaSource::ImageLibrary { nasa_id }) => {
                self.get_image_library_data(&nasa_id).await
            }
            None => {
                HttpResponse::NotFound().json(json!({ "error_message": "NASA item not found" }))
            }
        }
    }
}

#[tokio::test]
async fn nasa() {
    let client = reqwest::Client::new();
    let scraper = Nasa::new(
        client,
        "https://svs.gsfc.nasa.gov/31373/#media_group_379948".to_string(),
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
}

#[tokio::test]
async fn nasa_image_library() {
    let client = reqwest::Client::new();
    let scraper = Nasa::new(
        client,
        "https://images.nasa.gov/details/iss074e0609033".to_string(),
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
    assert!(body_str.contains("iss074e0609033"));
}
