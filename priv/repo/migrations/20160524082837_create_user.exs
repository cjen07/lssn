defmodule Lssn.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string, null: false
      add :password_hash, :string

      timestamps
    end
    create unique_index(:users, [:name])
  end
end
