defmodule WUE.Repo.Migrations.AddPicture do
  use Ecto.Migration

  def change do
    create table(:pictures) do
      add(:shape, :map, null: false)
    end
  end
end
