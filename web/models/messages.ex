defmodule HolonetRelay.Messages do
  def folders do
    Enum.map ["inbox", "archive", "spam"], fn(folder) ->
      path = "messages/#{folder}"

      %{folder: folder,
        path: path,
        message_count: message_count(path)}
    end
  end

  def groups(folder_path) do
    {:ok, groups} = File.ls(folder_path)

    Enum.map groups, fn(group) ->
      path = Path.join(folder_path, group)

      %{group: group,
        path: path,
        message_count: message_count(path),
        message_overviews: message_overviews(path)}
    end
  end

  def message_overviews(group_path) do
    {:ok, message_files} = File.ls(group_path)

    Enum.map message_files, fn(message_file) ->
      path = Path.join(group_path, message_file)

      %{permalink: String.replace(message_file, ~r/.txt/, ""),
        path: path,
        subject: message_subject(path)}
    end
  end

  def message(permalink) do
    [message_path] = Path.wildcard(["messages/**/", permalink, ".txt"])
    folder = Enum.at(String.split(message_path, "/"), 1)

    %{folder: folder,
      lines: message_lines(message_path)}
  end

  def message_subject(message_path) do
    subject_line = Enum.find(message_lines(message_path), fn(x) -> String.starts_with?(x, "subject: ") end) || "(None)"

    subject_line
      |> String.replace("subject:", "")
      |> String.strip
  end

  def message_count(base_path) do
    Enum.count(Path.wildcard([base_path, "/**/", "*.txt"]))
  end

  def message_lines(message_path) do
    File.stream!(message_path) |> Enum.map &String.strip/1
  end

  def newest_timestamp do
    all_groups = Path.wildcard("messages/*/*")

    timestamps = Enum.map all_groups, fn(group) ->
      {:ok, file_stat} = File.stat(group)
      {date, _} = Map.fetch!(file_stat, :ctime)
      date
    end

    Enum.max(timestamps)
  end
end
