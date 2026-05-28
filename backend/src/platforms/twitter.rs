use actix_web::{HttpResponse, http::StatusCode};
use reqwest::Client;
use reqwest::header::{ACCEPT, ACCEPT_LANGUAGE, HeaderMap, HeaderValue, USER_AGENT};
use serde_json::{Value, json};

pub struct Twitter {
    client: Client,
    url: String,
}

impl Twitter {
    pub fn new(client: Client, url: String) -> Self {
        Self { client, url }
    }

    fn extract_tweet_id(url: &str) -> Option<&str> {
        url.split("/status/")
            .nth(1)
            .and_then(|s| s.split('?').next())
    }

    fn headers() -> HeaderMap {
        let mut headers = HeaderMap::new();
        headers.insert(ACCEPT, HeaderValue::from_static("*/*"));
        headers.insert(ACCEPT_LANGUAGE, HeaderValue::from_static("en-US,en;q=0.9"));
        headers.insert(USER_AGENT, HeaderValue::from_static(
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"
        ));
        headers.insert("Authorization", HeaderValue::from_static("Bearer AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA"));
        headers.insert("Content-Type", HeaderValue::from_static("application/json"));
        headers.insert("Origin", HeaderValue::from_static("https://x.com"));
        headers.insert("Referer", HeaderValue::from_static("https://x.com/"));
        headers.insert("Host", HeaderValue::from_static("api.x.com"));
        headers
    }

    pub async fn get_data(&self) -> HttpResponse {
        let tweet_id = if let Some(id) = Self::extract_tweet_id(&self.url) {
            id.to_string()
        } else {
            return HttpResponse::NotFound().json(json!({ "error_message": "Tweet not found" }));
        };

        let url = "https://api.x.com/graphql/aFvUsJm2c-oDkJV75blV6g/TweetResultByRestId";

        let features_json = r#"{
            "creator_subscriptions_tweet_preview_api_enabled": true,
            "premium_content_api_read_enabled": false,
            "communities_web_enable_tweet_community_results_fetch": true,
            "c9s_tweet_anatomy_moderator_badge_enabled": true,
            "responsive_web_grok_analyze_button_fetch_trends_enabled": false,
            "responsive_web_grok_analyze_post_followups_enabled": false,
            "responsive_web_jetfuel_frame": true,
            "responsive_web_grok_share_attachment_enabled": true,
            "articles_preview_enabled": true,
            "responsive_web_edit_tweet_api_enabled": true,
            "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true,
            "view_counts_everywhere_api_enabled": true,
            "longform_notetweets_consumption_enabled": true,
            "responsive_web_twitter_article_tweet_consumption_enabled": true,
            "tweet_awards_web_tipping_enabled": false,
            "responsive_web_grok_show_grok_translated_post": false,
            "responsive_web_grok_analysis_button_from_backend": true,
            "creator_subscriptions_quote_tweet_preview_enabled": false,
            "freedom_of_speech_not_reach_fetch_enabled": true,
            "standardized_nudges_misinfo": true,
            "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true,
            "longform_notetweets_rich_text_read_enabled": true,
            "longform_notetweets_inline_media_enabled": true,
            "profile_label_improvements_pcf_label_in_post_enabled": true,
            "responsive_web_profile_redirect_enabled": false,
            "rweb_tipjar_consumption_enabled": true,
            "verified_phone_label_enabled": false,
            "responsive_web_grok_image_annotation_enabled": true,
            "responsive_web_grok_imagine_annotation_enabled": true,
            "responsive_web_grok_community_note_auto_translation_is_enabled": false,
            "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false,
            "responsive_web_graphql_timeline_navigation_enabled": true,
            "responsive_web_enhance_cards_enabled": false
        }"#;

        let field_toggles_json = r#"{
            "withArticleRichContentState": true,
            "withArticlePlainText": false
        }"#;

        let params = [
            (
                "variables",
                format!(
                    "{{\"tweetId\":\"{}\",\"includePromotedContent\":true,\"withBirdwatchNotes\":true,\"withVoice\":true,\"withCommunity\":true}}",
                    tweet_id
                ),
            ),
            ("features", features_json.to_owned()),
            ("fieldToggles", field_toggles_json.to_owned()),
        ];

        let resp = match self
            .client
            .get(url)
            .headers(Self::headers())
            .query(&params)
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

        let mut out = Vec::new();

        if let Some(legacy) = data
            .get("data")
            .and_then(|d| d.get("tweetResult"))
            .and_then(|t| t.get("result"))
            .and_then(|r| r.get("legacy"))
        {
            if let Some(extended_entities) = legacy
                .get("extended_entities")
                .and_then(|e| e.get("media"))
                .and_then(|m| m.as_array())
            {
                for media in extended_entities {
                    if let Some(video_info) = media
                        .get("video_info")
                        .and_then(|v| v.get("variants"))
                        .and_then(|v| v.as_array())
                    {
                        let mut highest_bitrate = 0;
                        let mut best_url = String::new();

                        for variant in video_info {
                            if let (Some(bitrate), Some(url)) = (
                                variant.get("bitrate").and_then(|b| b.as_u64()),
                                variant.get("url").and_then(|u| u.as_str()),
                            ) {
                                if bitrate > highest_bitrate && url.contains("video/") {
                                    highest_bitrate = bitrate;
                                    best_url = url.to_string();
                                }
                            }
                        }

                        if !best_url.is_empty() {
                            out.push(json!(best_url));
                        }
                    }

                    if let Some(media_url) = media.get("media_url_https").and_then(|u| u.as_str()) {
                        out.push(json!(media_url));
                    }
                }
            }
        }

        let result = json!({
            "data": out,
            "total": out.len(),
            "platform": "twitter"
        });

        HttpResponse::Ok().json(result)
    }
}

#[tokio::test]
async fn twitter() {
    let client = reqwest::Client::new();
    let scraper = Twitter::new(
        client,
        "https://x.com/i/status/2003082280378773557".to_string(),
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
