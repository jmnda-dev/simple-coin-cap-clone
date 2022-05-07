import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :app, AppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "xpkOmforc+HSnsEykYzyOFRHzM3fxuyrjrGaP/2n6W6HzjEwjkdQTZ3qOqRFrmiX",
  server: false

# In test we don't send emails.
config :app, App.Mailer,
  adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
