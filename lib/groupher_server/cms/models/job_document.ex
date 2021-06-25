defmodule GroupherServer.CMS.Model.JobDocument do
  @moduledoc """
  mainly for full-text search
  """
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.CMS
  alias CMS.Model.Job

  @timestamps_opts [type: :utc_datetime_usec]

  @max_body_length get_config(:article, :max_length)
  @min_body_length get_config(:article, :min_length)

  @required_fields ~w(body body_html job_id)a
  @optional_fields []

  @type t :: %JobDocument{}
  schema "job_documents" do
    belongs_to(:job, Job, foreign_key: :job_id)

    field(:body, :string)
    field(:body_html, :string)
    field(:toc, :map)
  end

  @doc false
  def changeset(%JobDocument{} = job, attrs) do
    job
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> validate_length(:body, min: @min_body_length, max: @max_body_length)
  end

  @doc false
  def update_changeset(%JobDocument{} = job, attrs) do
    job
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_length(:body, min: @min_body_length, max: @max_body_length)
  end
end
