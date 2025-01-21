mod certificate;

use axum::{
    http::{header, StatusCode},
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use certificate::Certificate;
use std::env;
use tokio::net::TcpListener;
use tower_http::cors::CorsLayer;

#[tokio::main]
async fn main() {
    let host = "0.0.0.0";
    let port = env::var("GENKEY_PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse::<u16>()
        .expect("Failed to parse `GENKEY_PORT`");
    let app = Router::new()
        .route("/status", get(status))
        .route("/pkcs12", post(generate_key))
        .layer(CorsLayer::very_permissive());

    println!("Listening on {}:{}", host, port);

    let addr = format!("{host}:{port}");
    let listener = TcpListener::bind(&addr).await.unwrap();
    axum::serve(listener, app.into_make_service()).await.unwrap();
}

async fn status() -> &'static str {
    "OK"
}

async fn generate_key(Json(payload): Json<Certificate>) -> impl IntoResponse {
    (
        StatusCode::OK,
        [(header::CONTENT_TYPE, "application/x-pkcs12")],
        payload.to_pkcs12(),
    )
}
