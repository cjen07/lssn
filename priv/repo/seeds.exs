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

Repo.insert!(%User{name: "lecturer1", type: "user", password_hash: Bcrypt.hashpwsalt("lecturer1")})

 # admin = Repo.get User, 1
 # cs = User.changeset admin, %{name: "admin", type: "admin", password: "admin", password_hash: Bcrypt.hashpwsalt("admin")}
 # Repo.update!(cs)