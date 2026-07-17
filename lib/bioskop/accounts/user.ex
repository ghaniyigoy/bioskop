defmodule Bioskop.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :nama, :string
    field :email, :string

    has_many :tickets, Bioskop.Ticketing.Ticket

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:nama, :email])
    |> validate_required([:nama, :email])
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+$/)
    |> unique_constraint(:email)
  end
end
