use actix_web::{HttpResponse, http::StatusCode};
use reqwest::Client;
use reqwest::header::{
    ACCEPT, ACCEPT_LANGUAGE, CONTENT_TYPE, HeaderMap, HeaderValue, ORIGIN, REFERER, USER_AGENT,
};
use scraper::{Html, Selector};
use serde_json::{Value, json};
use std::collections::HashSet;

const GRAPHQL_URL: &str = "https://www.instagram.com/graphql/query/";
const GRAPHQL_DOC_ID: &str = "10015901848480474";
const GRAPHQL_LSD: &str = "AVqbxe3J_YA";
const INSTAGRAM_APP_ID: &str = "1217981644879628";
const INSTAGRAM_ASBD_ID: &str = "129477";
const INSTAGRAM_CSRF_TOKEN: &str = "RVDUooU5MYsBbS1CNN3CzVAuEP8oHB52";

pub struct Instagram {
    client: Client,
    url: String,
}

impl Instagram {
    pub fn new(client: Client, url: String) -> Self {
        Self { client, url }
    }

    fn user_agent() -> &'static str {
        "Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.141 Mobile Safari/537.36"
    }

    fn page_headers() -> HeaderMap {
        let mut headers = HeaderMap::new();
        headers.insert(
            ACCEPT,
            HeaderValue::from_static(
                "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            ),
        );
        headers.insert(ACCEPT_LANGUAGE, HeaderValue::from_static("en-US,en;q=0.9"));
        headers.insert(USER_AGENT, HeaderValue::from_static(Self::user_agent()));
        headers
    }

    fn graphql_headers(referer: &str) -> Result<HeaderMap, String> {
        let mut headers = HeaderMap::new();
        headers.insert(ACCEPT, HeaderValue::from_static("*/*"));
        headers.insert(ACCEPT_LANGUAGE, HeaderValue::from_static("en-US,en;q=0.5"));
        headers.insert(
            CONTENT_TYPE,
            HeaderValue::from_static("application/x-www-form-urlencoded"),
        );
        headers.insert(USER_AGENT, HeaderValue::from_static(Self::user_agent()));
        headers.insert(
            ORIGIN,
            HeaderValue::from_static("https://www.instagram.com"),
        );
        headers.insert(
            REFERER,
            HeaderValue::from_str(referer).map_err(|e| format!("Invalid Instagram URL: {e}"))?,
        );
        headers.insert(
            "X-FB-Friendly-Name",
            HeaderValue::from_static("PolarisPostActionLoadPostQueryQuery"),
        );
        headers.insert("X-IG-App-ID", HeaderValue::from_static(INSTAGRAM_APP_ID));
        headers.insert("X-FB-LSD", HeaderValue::from_static(GRAPHQL_LSD));
        headers.insert("X-ASBD-ID", HeaderValue::from_static(INSTAGRAM_ASBD_ID));
        headers.insert(
            "X-CSRFToken",
            HeaderValue::from_static(INSTAGRAM_CSRF_TOKEN),
        );
        headers.insert("Sec-Fetch-Dest", HeaderValue::from_static("empty"));
        headers.insert("Sec-Fetch-Mode", HeaderValue::from_static("cors"));
        headers.insert("Sec-Fetch-Site", HeaderValue::from_static("same-origin"));
        Ok(headers)
    }

    fn extract_shortcode(url: &str) -> Option<&str> {
        url.split("/reel/")
            .nth(1)
            .or_else(|| url.split("/reels/").nth(1))
            .or_else(|| url.split("/p/").nth(1))
            .or_else(|| url.split("/tv/").nth(1))
            .and_then(|s| s.split('/').next())
            .and_then(|s| s.split('?').next())
            .filter(|s| !s.is_empty())
    }

    async fn fetch_graphql_media(&self, shortcode: &str) -> Result<Value, String> {
        let variables = json!({
            "shortcode": shortcode,
            "fetch_tagged_user_count": null,
            "hoisted_comment_id": null,
            "hoisted_reply_id": null
        });
        let variables =
            serde_json::to_string(&variables).map_err(|e| format!("Variables failed: {e}"))?;
        let form = [
            ("variables", variables.as_str()),
            ("server_timestamps", "true"),
            ("doc_id", GRAPHQL_DOC_ID),
        ];

        let response = self
            .client
            .post(GRAPHQL_URL)
            .headers(Self::graphql_headers(&self.url)?)
            .form(&form)
            .send()
            .await
            .map_err(|e| format!("Instagram GraphQL request failed: {e}"))?;

        if !response.status().is_success() {
            return Err(format!(
                "Instagram GraphQL returned status {}",
                response.status()
            ));
        }

        let body = response
            .text()
            .await
            .map_err(|e| format!("Instagram GraphQL body failed: {e}"))?;
        let body = body.strip_prefix("for (;;);").unwrap_or(&body);
        let data: Value = serde_json::from_str(body)
            .map_err(|e| format!("Instagram GraphQL JSON failed: {e}"))?;

        data.get("data")
            .and_then(|data| data.get("xdt_shortcode_media"))
            .filter(|media| !media.is_null())
            .cloned()
            .ok_or_else(|| "Instagram item not found in GraphQL response".to_string())
    }

    fn push_url(out: &mut Vec<String>, seen: &mut HashSet<String>, value: Option<&Value>) {
        if let Some(url) = value.and_then(Value::as_str) {
            let url = url.replace("&amp;", "&");
            if !url.is_empty() && seen.insert(url.clone()) {
                out.push(url);
            }
        }
    }

    fn push_best_image(node: &Value, out: &mut Vec<String>, seen: &mut HashSet<String>) {
        if let Some(resource) = node
            .get("display_resources")
            .and_then(Value::as_array)
            .and_then(|resources| resources.last())
        {
            Self::push_url(out, seen, resource.get("src"));
            return;
        }

        Self::push_url(out, seen, node.get("display_url"));
    }

    fn extract_graphql_urls(item: &Value) -> Vec<String> {
        let mut out = Vec::new();
        let mut seen = HashSet::new();

        Self::push_url(&mut out, &mut seen, item.get("thumbnail_src"));
        Self::push_best_image(item, &mut out, &mut seen);

        if let Some(edges) = item
            .get("edge_sidecar_to_children")
            .and_then(|sidecar| sidecar.get("edges"))
            .and_then(Value::as_array)
        {
            for edge in edges {
                let Some(node) = edge.get("node") else {
                    continue;
                };
                Self::push_url(&mut out, &mut seen, node.get("video_url"));
                Self::push_best_image(node, &mut out, &mut seen);
            }
        } else {
            Self::push_url(&mut out, &mut seen, item.get("video_url"));
        }

        out
    }

    async fn fetch_page_media(&self, shortcode: &str) -> Result<Vec<String>, String> {
        let page_url = format!("https://www.instagram.com/p/{shortcode}/");
        let response = self
            .client
            .get(&page_url)
            .headers(Self::page_headers())
            .send()
            .await
            .map_err(|e| format!("Instagram page request failed: {e}"))?;

        if !response.status().is_success() {
            return Err(format!(
                "Instagram page returned status {}",
                response.status()
            ));
        }

        let html = response
            .text()
            .await
            .map_err(|e| format!("Instagram page body failed: {e}"))?;
        let document = Html::parse_document(&html);
        let mut out = Vec::new();
        let mut seen = HashSet::new();

        for property in ["og:video:secure_url", "og:video", "og:image"] {
            let selector = Selector::parse(&format!("meta[property=\"{property}\"]"))
                .map_err(|e| format!("Instagram selector failed: {e}"))?;
            for element in document.select(&selector) {
                if let Some(url) = element.value().attr("content") {
                    let url = url.replace("&amp;", "&");
                    if !url.is_empty() && seen.insert(url.clone()) {
                        out.push(url);
                    }
                }
            }
        }

        if out.is_empty() {
            Err("No media found on Instagram page".to_string())
        } else {
            Ok(out)
        }
    }

    pub async fn get_data(&self) -> HttpResponse {
        let shortcode = match Self::extract_shortcode(&self.url) {
            Some(shortcode) => shortcode.to_string(),
            None => {
                return HttpResponse::NotFound()
                    .json(json!({ "error_message": "Could not extract Instagram post ID" }));
            }
        };

        let results = match self.fetch_graphql_media(&shortcode).await {
            Ok(item) => {
                let urls = Self::extract_graphql_urls(&item);
                if urls.is_empty() {
                    self.fetch_page_media(&shortcode).await
                } else {
                    Ok(urls)
                }
            }
            Err(graphql_error) => self
                .fetch_page_media(&shortcode)
                .await
                .map_err(|page_error| format!("{graphql_error}; {page_error}")),
        };

        match results {
            Ok(data) => HttpResponse::Ok().json(json!({
                "data": data,
                "total": data.len(),
                "platform": "instagram"
            })),
            Err(error) => {
                HttpResponse::build(StatusCode::BAD_GATEWAY).json(json!({ "error_message": error }))
            }
        }
    }
}

#[tokio::test]
async fn instagram() {
    let client = reqwest::Client::new();
    let scraper = Instagram::new(
        client,
        "https://www.instagram.com/p/DajR8O7PHb3/".to_string(),
    );
    let response = scraper.get_data().await;
    let status = response.status();
    println!("Status: {status}");
    let body_bytes = actix_web::body::to_bytes(response.into_body())
        .await
        .unwrap();
    let body_str = String::from_utf8(body_bytes.to_vec()).unwrap();
    println!("Body: {body_str}");
    assert_eq!(status, StatusCode::OK);

    let result: Value = serde_json::from_str(&body_str).unwrap();
    let media = result["data"].as_array().unwrap();
    assert!(!media.is_empty(), "Expected at least one Instagram URL");
    assert!(
        media.iter().any(|url| {
            url.as_str()
                .is_some_and(|url| url.contains("cdninstagram.com") || url.contains("fbcdn.net"))
        }),
        "Expected an Instagram CDN URL"
    );
    assert!(
        media
            .iter()
            .any(|url| url.as_str().is_some_and(|url| url.contains(".mp4"))),
        "Expected an Instagram video URL"
    );
}
