use actix_web::{HttpResponse, http::StatusCode};
use reqwest::Client;
use reqwest::header::{ACCEPT, ACCEPT_LANGUAGE, CONTENT_TYPE, HeaderMap, HeaderValue, USER_AGENT};
use serde_json::{Value, json};

pub struct Instagram {
    client: Client,
    url: String,
}

impl Instagram {
    pub fn new(client: Client, url: String) -> Self {
        Self { client, url }
    }

    fn graphql() -> &'static str {
        "https://www.instagram.com/graphql/query/"
    }

    fn headers() -> HeaderMap {
        let mut headers = HeaderMap::new();
        headers.insert(ACCEPT, HeaderValue::from_static("*/*"));
        headers.insert(ACCEPT_LANGUAGE, HeaderValue::from_static("en-US,en;q=0.9"));
        headers.insert(
            CONTENT_TYPE,
            HeaderValue::from_static("application/x-www-form-urlencoded"),
        );
        headers.insert(USER_AGENT, HeaderValue::from_static(
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0"
        ));
        headers.insert(
            "Origin",
            HeaderValue::from_static("https://www.instagram.com"),
        );
        headers.insert(
            "Referer",
            HeaderValue::from_static("https://www.instagram.com"),
        );
        headers.insert("X-CSRFToken", HeaderValue::from_static("11111111111"));
        headers
    }

    fn extract_item_id(url: &str) -> Option<&str> {
        url.split("/reel/")
            .nth(1)
            .or_else(|| url.split("/p/").nth(1))
            .and_then(|s| s.split('/').next())
    }

    pub async fn get_data(&self) -> HttpResponse {
        let item_id = if let Some(id) = Self::extract_item_id(&self.url) {
            id.to_string()
        } else {
            return HttpResponse::NotFound().json(json!({ "error_message": "Post not found" }));
        };

        let graphql_data = json!({
            "av": "0",
            "__d": "www",
            "__user": "0",
            "__a": "1",
            "__req": "a",
            "__hs": "20229.HYP:instagram_web_pkg.2.1...0",
            "dpr": "1",
            "__ccg": "GOOD",
            "__rev": "1023049274",
            "__comet_req": "7",
            "lsd": "AVqQ3As1H7g",
            "jazoest": "2855",
            "__spin_r": "1023049274",
            "__spin_b": "trunk",
            "__spin_t": "1747835843",
            "fb_api_caller_class": "RelayModern",
            "fb_api_req_friendly_name": "PolarisPostActionLoadPostQueryQuery",
            "variables": format!("{{\"shortcode\":\"{}\",\"fetch_tagged_user_count\":null,\"hoisted_comment_id\":null,\"hoisted_reply_id\":null}}", item_id),
            "server_timestamps": "true",
            "doc_id": "9510064595728286"
        });

        let resp = match self
            .client
            .post(Self::graphql())
            .headers(Self::headers())
            .form(&graphql_data)
            .send()
            .await
        {
            Ok(r) => r,
            Err(e) => {
                return HttpResponse::build(StatusCode::BAD_GATEWAY)
                    .json(json!({ "error_message": format!("Request failed: {}", e) }));
            }
        };

        let data: Value = match resp.json().await {
            Ok(d) => d,
            Err(e) => {
                return HttpResponse::build(StatusCode::BAD_GATEWAY)
                    .json(json!({ "error_message": format!("JSON parse failed: {}", e) }));
            }
        };

        let item = match data.get("data").and_then(|d| d.get("xdt_shortcode_media")) {
            Some(i) => i,
            None => {
                return HttpResponse::build(StatusCode::BAD_GATEWAY)
                    .json(json!({ "error_message": "Item not found" }));
            }
        };

        let mut out = Vec::new();

        if let Some(thumbnail_src) = item.get("thumbnail_src") {
            out.push(thumbnail_src.clone());
        }

        if let Some(resources) = item.get("display_resources").and_then(|r| r.as_array()) {
            if let Some(last) = resources.last() {
                if let Some(video_url) = last.get("src") {
                    out.push(video_url.clone());
                }
            }
        }

        if let Some(edges) = item
            .get("edge_sidecar_to_children")
            .and_then(|c| c.get("edges"))
            .and_then(|a| a.as_array())
        {
            for edge in edges {
                if let Some(node) = edge.get("node") {
                    if let Some(video_url) = node.get("video_url") {
                        out.push(video_url.clone());
                    }
                    if let Some(display_url) = node.get("display_url") {
                        out.push(display_url.clone());
                    }
                    if let Some(resources) =
                        node.get("display_resources").and_then(|r| r.as_array())
                    {
                        if let Some(last) = resources.last() {
                            if let Some(video_url) = last.get("src") {
                                out.push(video_url.clone());
                            }
                        }
                    }
                    if let Some(video) = node.get("video_url") {
                        out.push(video.clone());
                    }
                }
            }
        } else if let Some(video_url) = item.get("video_url") {
            out.push(video_url.clone());
        }

        let result = json!({
            "data": out,
            "total": out.len(),
            "platform": "instagram"
        });

        HttpResponse::Ok().json(result)
    }
}

#[tokio::test]
async fn instagram() {
    let client = reqwest::Client::new();
    let scraper = Instagram::new(
        client,
        "https://www.instagram.com/reel/DHm7knuzl1D".to_string(),
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
