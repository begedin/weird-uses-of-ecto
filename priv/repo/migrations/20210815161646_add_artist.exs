defmodule WUE.Repo.Migrations.AddArtist do
  use Ecto.Migration

  def change do
    create table(:artists) do
      add(:country, :string, null: false)
      add(:name, :string, null: false)
    end

    flush()

    alter table(:pictures) do
      add(:artist_id, references(:artists), null: true)
    end
  end
end
