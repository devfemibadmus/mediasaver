use actix_web::{HttpResponse, http::StatusCode};
use reqwest::Client;
use reqwest::header::{ACCEPT, ACCEPT_LANGUAGE, HeaderMap, HeaderValue, USER_AGENT};
use scraper::{Html, Selector};
use serde_json::{Value, json};

pub struct Snapchat {
    client: Client,
    url: String,
}

impl Snapchat {
    pub fn new(client: Client, url: String) -> Self {
        Self { client, url }
    }

    fn headers() -> HeaderMap {
        let mut headers = HeaderMap::new();
        headers.insert(USER_AGENT, HeaderValue::from_static("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"));
        headers.insert(
            ACCEPT,
            HeaderValue::from_static(
                "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            ),
        );
        headers.insert(ACCEPT_LANGUAGE, HeaderValue::from_static("en-US,en;q=0.9"));
        headers.insert(
            "Referer",
            HeaderValue::from_static("https://www.snapchat.com/"),
        );
        headers.insert("Connection", HeaderValue::from_static("keep-alive"));
        headers
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

        let html = match resp.text().await {
            Ok(h) => h,
            Err(e) => {
                return HttpResponse::build(StatusCode::BAD_GATEWAY)
                    .json(json!({ "error_message": format!("HTML parse failed: {}", e) }));
            }
        };

        let document = Html::parse_document(&html);
        let selector = Selector::parse("script#__NEXT_DATA__").unwrap();

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

        let snap_list = match data
            .get("props")
            .and_then(|p| p.get("pageProps"))
            .and_then(|pp| pp.get("story").or_else(|| pp.get("highlight")))
            .and_then(|s| s.get("snapList"))
            .or_else(|| {
                data.get("props")
                    .and_then(|p| p.get("pageProps"))
                    .and_then(|pp| pp.get("spotlightFeed"))
                    .and_then(|sf| {
                        sf.get("spotlightStories")
                            .and_then(|ss| ss.get(0))
                            .and_then(|st| st.get("story"))
                            .and_then(|s| s.get("snapList"))
                    })
            })
            .and_then(|sl| sl.as_array())
        {
            Some(sl) => sl,
            None => {
                return HttpResponse::build(StatusCode::BAD_GATEWAY)
                    .json(json!({ "error_message": "Snap list not found" }));
            }
        };

        let mut out = Vec::new();
        for snap in snap_list {
            let preview = snap
                .get("snapUrls")
                .and_then(|u| u.get("mediaPreviewUrl"))
                .and_then(|p| p.get("value"))
                .and_then(|v| v.as_str())
                .unwrap_or("")
                .to_string();

            let media = snap
                .get("snapUrls")
                .and_then(|u| u.get("mediaUrl"))
                .and_then(|m| m.as_str())
                .unwrap_or("")
                .to_string();

            out.push(media);
            out.push(preview);
        }

        let result = json!({
            "data": out,
            "total": out.len(),
            "platform": "snapchat"
        });

        HttpResponse::Ok().json(result)
    }
}

#[tokio::test]
async fn snapchat() {
    let client = reqwest::Client::new();
    let scraper = Snapchat::new(client, "https://www.snapchat.com/spotlight/W7_EDlXWTBiXAEEniNoMPwAAYd2V5eXVoenV2AZvzGGUEAZvy3AKSAAAAAQ?ref=web_spotlight".to_string());
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
