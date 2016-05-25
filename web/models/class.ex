defmodule Lssn.Class do
  use Lssn.Web, :model

  schema "classes" do
    field :name, :string
    field :config, :string
    field :record, :string

    timestamps
  end

  @required_fields ~w(name config record)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:name)
  end
end
