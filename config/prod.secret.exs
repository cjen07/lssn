use Mix.Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
config :lssn, Lssn.Endpoint,
  secret_key_base: "6QTv1qASkK/jz0NQM29ks7cu9Dqkp05jKdzr3lCWDhkjcyS6UZgS6qF7Bbr2iXuK"

# Configure your database
config :lssn, Lssn.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "lssn_prod",
  pool_size: 20
