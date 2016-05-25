defmodule Lssn.Repo.Migrations.CreateClass do
  use Ecto.Migration

  def change do
    create table(:classes) do
      add :name, :string, null: false
      add :config, :string, null: false
      add :record, :string, null: false

      timestamps
    end
    create unique_index(:classes, [:name])
  end
end
