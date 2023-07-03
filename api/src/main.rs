mod key;

use actix_web::{get, post, web, App, HttpResponse, HttpServer, Responder};
use std::env;

#[tokio::main]
async fn main() -> std::io::Result<()> {
    let port = env::var("GENKEY_PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse::<u16>()
        .expect("Failed to parse `GENKEY_PORT`");
    let host = env::var("GENKEY_HOST").unwrap_or_else(|_| "0.0.0.0".to_string());
    println!("Listening at {}:{}", host, port);
    HttpServer::new(|| App::new().service(status).service(generate_key))
        .bind((host, port))?
        .run()
        .await
}

#[get("/status")]
async fn status() -> impl Responder {
    "OK"
}

#[post("/pkcs12")]
async fn generate_key(key: web::Json<key::Key>) -> HttpResponse {
    HttpResponse::Ok()
        .content_type("application/x-pkcs12")
        .body(key.to_pkcs12())
}
