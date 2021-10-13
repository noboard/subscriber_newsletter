#![allow(clippy::toplevel_ref_arg)]
use std::net::TcpListener;
use subscriber_newsletter::startup::run;
use subscriber_newsletter::configuration::get_configuration;
use subscriber_newsletter::telemetry::{get_subscriber, init_subscriber};
use sqlx::postgres::PgPoolOptions;

#[actix_web::main]
async fn main() -> std::io::Result<()> {

    let subscriber = get_subscriber(
        "subscriber_newsletter".into(),
        "info".into(),
        std::io::stdout
    );

    init_subscriber(subscriber);

    //Panic if we can't read the configuration file
    let configuration = get_configuration().expect("Failed to read configuration");
    let connection_pool = PgPoolOptions::new()
        .connect_timeout(std::time::Duration::from_secs(30))
        .connect_lazy_with(configuration.database.with_db());


    let address = format!("{}:{}", configuration.application.host, configuration.application.port);
    let listener = TcpListener::bind(address)
        .expect("main() failed to bind to random port!");

    run(listener, connection_pool)?.await
}