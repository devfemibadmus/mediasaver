use actix_cors::Cors;
use actix_web::http::header::ContentType;
use actix_web::{App, HttpRequest, HttpResponse, HttpServer, Responder, get, route, web};
use regex::Regex;
use rust_embed::RustEmbed;
use std::collections::HashMap;
use tera::{Context, Tera};

mod platforms;
use platforms::{
    facebook::Facebook, instagram::Instagram, nasa::Nasa, snapchat::Snapchat, tiktok::TikTok,
    twitter::Twitter,
};

#[derive(RustEmbed)]
#[folder = "website/"]
struct Asset;

async fn static_handler(path: web::Path<String>) -> impl Responder {
    let file_path = format!("static/{}", path.into_inner());
    if let Some(file) = Asset::get(&file_path) {
        let body = file.data.into_owned();
        let mime = mime_guess::from_path(file_path).first_or_octet_stream();
        HttpResponse::Ok()
            .content_type(ContentType::from(actix_web::http::header::ContentType(
                mime,
            )))
            .body(body)
    } else {
        HttpResponse::NotFound().body("not found")
    }
}

struct Validator;

impl Validator {
    fn validate(url: &str) -> &'static str {
        let url = if url.ends_with('/') || url.contains('#') || url.contains('?') {
            url.to_string()
        } else {
            format!("{}/", url)
        };
        let patterns = [
            (r"tiktok\.com/.*/", "TikTok"),
            (
                r"instagram\.com/(p|reel|reels|tv)/([A-Za-z0-9_-]+)/?",
                "Instagram",
            ),
            (r"(facebook\.com/.*/|fb\.watch/.*/)", "Facebook"),
            (r"snapchat\.com/t/", "Snapchat"),
            (r"(twitter\.com/|x\.com/).*/status/", "Twitter"),
            (r"svs\.gsfc\.nasa\.gov/\d+/?(#media_group_\d+)?", "NASA"),
        ];
        for (pattern, platform) in patterns.iter() {
            if Regex::new(pattern).unwrap().is_match(&url) {
                return platform;
            }
        }
        "Invalid URL"
    }
}

#[route("/api/", method = "GET", method = "POST")]
async fn api_handler(
    req: HttpRequest,
    client: web::Data<reqwest::Client>,
    body: web::Bytes,
    query: web::Query<HashMap<String, String>>,
) -> impl Responder {
    let user_agent = req
        .headers()
        .get("User-Agent")
        .and_then(|value| value.to_str().ok())
        .unwrap_or("")
        .to_lowercase();

    let is_apple_request = ["iphone", "ipad", "ipod", "ios", "macintosh", "mac os"]
        .iter()
        .any(|token| user_agent.contains(token));

    let json: HashMap<String, serde_json::Value> =
        serde_json::from_slice(&body).unwrap_or_default();
    let url = json
        .get("url")
        .and_then(|v| v.as_str())
        .or_else(|| query.get("url").map(|s| s.as_str()));

    if url.is_none() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "error": true,
            "message": "URL is required",
            "error_message": "URL is required"
        }));
    }

    let url = url.unwrap();
    let platform = Validator::validate(url);

    if platform != "NASA" && is_apple_request {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "error": true,
            "message": "Unsupported URL",
            "error_message": "Unsupported URL"
        }));
    }

    match platform {
        "Facebook" => {
            let mut fb = Facebook::new(
                client.get_ref().clone(),
                &url.replace("web.facebook", "www.facebook"),
            );
            fb.get_data().await
        }
        "Instagram" => {
            let insta = Instagram::new(client.get_ref().clone(), url.to_string());
            insta.get_data().await
        }
        "TikTok" => {
            let tiktok = TikTok::new(client.get_ref().clone(), url.to_string());
            tiktok.get_data().await
        }
        "Snapchat" => {
            let snap = Snapchat::new(client.get_ref().clone(), url.to_string());
            snap.get_data().await
        }
        "Twitter" => {
            let twitter = Twitter::new(client.get_ref().clone(), url.to_string());
            twitter.get_data().await
        }
        "NASA" => {
            let nasa = Nasa::new(client.get_ref().clone(), url.to_string());
            nasa.get_data().await
        }
        _ => HttpResponse::BadRequest().json(serde_json::json!({
            "error": true,
            "message": "Unsupported URL",
            "error_message": "Unsupported URL"
        })),
        // _ => HttpResponse::Ok().json(serde_json::json!({
        //     "data": [],
        //     "total": 0,
        //     "platform": "404"
        // })),
    }
}

#[get("/")]
async fn home() -> impl Responder {
    let ctx = Context::new();
    if let Some(template) = Asset::get("home.html") {
        let rendered = Tera::one_off(
            std::str::from_utf8(template.data.as_ref()).unwrap(),
            &ctx,
            true,
        )
        .unwrap();
        HttpResponse::Ok()
            .content_type("text/html; charset=utf-8")
            .body(rendered)
    } else {
        HttpResponse::InternalServerError().body("Template not found")
    }
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let client = reqwest::Client::new();

    HttpServer::new(move || {
        App::new()
            .wrap(
                Cors::default()
                    .allow_any_origin()
                    .allow_any_method()
                    .allow_any_header()
                    .max_age(3600),
            )
            .service(home)
            .service(api_handler)
            .route("/static/{_:.*}", web::get().to(static_handler))
            .app_data(web::Data::new(client.clone()))
    })
    .bind(("127.0.0.1", 8080))?
    .run()
    .await
}
