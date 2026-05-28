use actix_web::{HttpResponse, http::StatusCode};
use reqwest::Client;
use reqwest::header::{ACCEPT, ACCEPT_LANGUAGE, HeaderMap, HeaderValue, USER_AGENT};
use scraper::{Html, Selector};
use serde_json::{Value, json};

pub struct TikTok {
    client: Client,
    url: String,
}

impl TikTok {
    pub fn new(client: Client, url: String) -> Self {
        Self { client, url }
    }

    fn headers() -> HeaderMap {
        let mut headers = HeaderMap::new();
        headers.insert(USER_AGENT, HeaderValue::from_static("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"));
        headers.insert(
            ACCEPT,
            HeaderValue::from_static(
                "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            ),
        );
        headers.insert(ACCEPT_LANGUAGE, HeaderValue::from_static("en-US,en;q=0.9"));
        headers.insert(
            "Referer",
            HeaderValue::from_static("https://www.tiktok.com/"),
        );
        headers.insert("Connection", HeaderValue::from_static("keep-alive"));
        headers
    }

    fn find_url_lists(obj: &serde_json::Value) -> Vec<Vec<String>> {
        let mut last_url_list: Option<Vec<String>> = None;
        let mut stack = vec![obj];

        while let Some(current) = stack.pop() {
            if let Some(obj) = current.as_object() {
                for (key, value) in obj {
                    if key.to_lowercase() == "urllist" && value.is_array() {
                        if let Some(arr) = value.as_array() {
                            let list: Vec<String> = arr
                                .iter()
                                .filter_map(|v| v.as_str().map(String::from))
                                .collect();
                            if !list.is_empty() {
                                last_url_list = Some(list);
                            }
                        }
                    }
                    stack.push(value);
                }
            } else if let Some(arr) = current.as_array() {
                for item in arr {
                    stack.push(item);
                }
            }
        }

        match last_url_list {
            Some(list) => vec![list],
            None => Vec::new(),
        }
    }

    pub async fn get_data(&self) -> HttpResponse {
        let resp = match self
            .client
            .get(&self.url)
            .headers(Self::headers())
            .send()
            .await
        {
            Ok(r) => r,
            Err(e) => {
                return HttpResponse::build(StatusCode::BAD_GATEWAY)
                    .json(json!({ "error_message": format!("Request failed: {}", e) }));
            }
        };

        let final_url = resp.url().to_string().replace("photo", "video");

        let resp = match self
            .client
            .get(&final_url)
            .headers(Self::headers())
            .send()
            .await
        {
            Ok(r) => r,
            Err(e) => {
                return HttpResponse::build(StatusCode::BAD_GATEWAY)
                    .json(json!({ "error_message": format!("Second request failed: {}", e) }));
            }
        };

        let html = match resp.text().await {
            Ok(h) => h,
            Err(e) => {
                return HttpResponse::build(StatusCode::BAD_GATEWAY)
                    .json(json!({ "error_message": format!("HTML parse failed: {}", e) }));
            }
        };

        let document = Html::parse_document(&html);
        let selector = Selector::parse("script#__UNIVERSAL_DATA_FOR_REHYDRATION__").unwrap();

        let script = match document.select(&selector).next() {
            Some(s) => s.inner_html(),
            None => {
                return HttpResponse::build(StatusCode::BAD_GATEWAY)
                    .json(json!({ "error_message": "Script not found" }));
            }
        };

        let data: Value = match serde_json::from_str(&script) {
            Ok(d) => d,
            Err(e) => {
                return HttpResponse::build(StatusCode::BAD_GATEWAY)
                    .json(json!({ "error_message": format!("JSON parse failed: {}", e) }));
            }
        };

        let all_url_lists = Self::find_url_lists(&data);

        let mut out = Vec::new();
        for url_list in all_url_lists {
            if let Some(url) = url_list.last() {
                let new_url = if url.contains("?dr=") {
                    url.clone()
                } else {
                    let parts: Vec<&str> = url.split('?').collect();
                    if parts.len() > 1 {
                        format!(
                            "https://api16-normal-useast5.tiktokv.us/aweme/v1/play/?faid=1988&{}",
                            parts[1].replace("&amp;", "&")
                        )
                    } else {
                        url.clone()
                    }
                };
                out.push(new_url);
            }
        }

        let result = json!({
            "data": out,
            "total": out.len(),
            "platform": "tiktok"
        });

        HttpResponse::Ok().json(result)
    }
}

#[tokio::test]
async fn tiktok() {
    let client = reqwest::Client::new();
    let scraper = TikTok::new(
        client,
        "https://vm.tiktok.com/ZSHK8GLq32Kjh-qQ9X4/".to_string(),
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
