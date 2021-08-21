defmodule WUE.Repo.Migrations.AddAlbum do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:albums) do
      add(:name, :string, null: false)
    end

    create unique_index(:albums, [:name])

    create table(:pictures_albums) do
      add(:album_id, references(:albums), null: false)
      add(:picture_id, references(:pictures), null: false)
    end

    alter table(:pictures) do
      add(:name, :string, null: true)
    end
  end
end
