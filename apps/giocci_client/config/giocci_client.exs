# This config is an example for Giocci Client Docker image
import Config

config :logger, :default_formatter,
  colors: [enabled: false],
  format: "\n$date $time $metadata[$level] $message\n"

# Path to Zenoh configuration in docker image
# Important: This must match the volume mount destination in docker-compose.yml
config :giocci_client, zenoh_config_file_path: "/app/zenoh.json"

# Unique client identifier
config :giocci_client, client_name: "giocci_client"

# Optional key prefix for Zenoh keys
# Important: This must match the key_prefix in relay and engine configurations
config :giocci_client, key_prefix: ""
