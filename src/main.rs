#![allow(clippy::toplevel_ref_arg)]
use subscriber_newsletter::configuration::get_configuration;
use subscriber_newsletter::startup::Application;
use subscriber_newsletter::telemetry::{get_subscriber, init_subscriber};

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
    let application = Application::build(configuration).await?;
    application.run_until_stopped().await?;
    Ok(())
}
