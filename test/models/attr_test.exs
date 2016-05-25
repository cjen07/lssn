defmodule Lssn.AttrTest do
  use Lssn.ModelCase

  alias Lssn.Attr

  @valid_attrs %{class: "some content", config: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Attr.changeset(%Attr{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Attr.changeset(%Attr{}, @invalid_attrs)
    refute changeset.valid?
  end
end
