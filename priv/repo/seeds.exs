# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Lssn.Repo.insert!(%Lssn.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Lssn.Repo
alias Lssn.User
alias Comeonin.Bcrypt

Repo.insert!(%User{name: "admin", password_hash: Bcrypt.hashpwsalt("admin")})