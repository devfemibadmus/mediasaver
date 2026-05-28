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

    fn extract_ids(url: &str) -> Option<(String, Option<u64>)> {
        let parsed = reqwest::Url::parse(url).ok()?;
        let page_id = parsed
            .path_segments()?
            .find(|segment| !segment.is_empty() && segment.chars().all(|ch| ch.is_ascii_digit()))?
            .to_string();

        let media_group_id = parsed
            .fragment()
            .and_then(|fragment| fragment.strip_prefix("media_group_"))
            .and_then(|id| id.parse::<u64>().ok());

        Some((page_id, media_group_id))
    }

    async fn fetch_json(&self, page_id: &str) -> Result<Value, String> {
        let api_url = format!("https://svs.gsfc.nasa.gov/api/{}", page_id);
        let mut last_error = String::from("Unknown request error");

        for attempt in 0..3 {
            let request = self.client.get(&api_url).headers(Self::headers()).send().await;

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

    fn push_url(out: &mut Vec<Value>, seen: &mut HashSet<String>, value: &Value) {
        if let Some(url) = value.get("url").and_then(|v| v.as_str()) {
            let url = url.trim();
            if !url.is_empty() && seen.insert(url.to_string()) {
                out.push(json!(url));
            }
        }
    }

    pub async fn get_data(&self) -> HttpResponse {
        let (page_id, media_group_id) = match Self::extract_ids(&self.url) {
            Some(ids) => ids,
            None => {
                return HttpResponse::NotFound()
                    .json(json!({ "error_message": "NASA item not found" }));
            }
        };

        let data = match self.fetch_json(&page_id).await {
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
