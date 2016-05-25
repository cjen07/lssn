ExUnit.start

Mix.Task.run "ecto.create", ~w(-r Lssn.Repo --quiet)
Mix.Task.run "ecto.migrate", ~w(-r Lssn.Repo --quiet)
Ecto.Adapters.SQL.begin_test_transaction(Lssn.Repo)

