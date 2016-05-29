defmodule Lssn.ClassController do
  use Lssn.Web, :controller

  alias Lssn.Class

  plug :scrub_params, "class" when action in [:create, :update]

  plug :authenticate1 when action in [:index, :record_new,
    :record_create, :record_edit, :update, :record_update,
    :export, :show, :import_new, :import_create]

  plug :authenticate2 when action in [:new, :item_new, :create,
  :item_create, :edit, :delete,
  :record_delete]

  defp authenticate1(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access that page")
      |> redirect(to: page_path(conn, :index))
      |> halt()
    end
  end

  defp authenticate2(conn, _opts) do
    if conn.assigns.current_user do
      if conn.assigns.current_user.type == "admin" do
        conn
      else
        conn
        |> put_flash(:error, "You must be admin to access that page")
        |> redirect(to: class_path(conn, :index))
        |> halt()
      end
    else
      conn
      |> put_flash(:error, "You must be logged in to access that page")
      |> redirect(to: page_path(conn, :index))
      |> halt()
    end
  end

  def index(conn, _params) do
    classes = Repo.all(Class)
    # test data
    {:ok, items} = JSON.encode([])
    render(conn, "index.html", classes: classes, items: items)
  end

  def new(conn, %{"items" => items}) do
    changeset = Class.changeset(%Class{})

    {:ok, itemss} = JSON.decode(items)
    render(conn, "new.html", changeset: changeset, items: items, itemss: itemss)
  end

  def item_new(conn, %{"items" => items}) do
    render(conn, "item_new.html", items: items, flag: true)
  end

  def record_new(conn, %{"id" => id}) do
    class = Repo.get!(Class, id)
    items = class.config
    {:ok, items} = JSON.decode(items)
    render(conn, "record_new.html", class: class, items: items)
  end

  def create(conn, %{"class" => class_params, "items" => items}) do

    {:ok, itemss} = JSON.decode(items)
    changeset = Class.changeset(%Class{}, Map.merge(class_params, %{"config" => items, "record" => "[]"}))

    if length(itemss) == 0 do
      render(conn, "new.html", changeset: changeset, items: items, itemss: itemss)
    else
      case Repo.insert(changeset) do
        {:ok, _class} ->
          conn
          |> put_flash(:info, "Class created successfully.")
          |> redirect(to: class_path(conn, :index))
        {:error, changeset} ->
          render(conn, "new.html", changeset: changeset, items: items, itemss: itemss)
      end
    end
  end

  def item_create(conn, %{"items" => items}) do

    # vacant String check and same-name check
    item = conn.params["new_item"]
    {:ok, items} = JSON.decode(items)

    item = if item["type"] != "sel", do: Map.put(item, "select", ""), else: item

    flag1 = items |> Enum.map(&(Map.get(&1, "name"))) |> Enum.find(fn x -> x == item["name"] end) |> is_nil() 

    flag2 = item["type"] != "sel" or item["select"] != ""

    case {item["name"] == "", flag1, flag2} do
      {false, true, true} -> 
        items = Enum.reverse([item | Enum.reverse(items)])
        IO.inspect items
        {:ok, items} = JSON.encode(items)
        conn = put_flash(conn, :info, "Item created successfully.")
        redirect(conn, to: class_path(conn, :new, items: items))
      _ ->
        {:ok, items} = JSON.encode(items)
        conn = put_flash(conn, :info, "Invalid item.")
        render(conn, "item_new.html", items: items, flag: flag2)
    end
  end

  defp date_format(record, items) do
    List.foldl(items, %{}, fn (n, acc) -> 
      case n["type"] do
        "date" -> 
          date = record[n["name"]]
          Map.merge(acc, %{n["name"] => date["year"] <> "-" <> date["month"] <> "-" <> date["day"]})
        _ -> Map.merge(acc, %{n["name"] => record[n["name"]]})

      end

    end)
  end

  defp format_date(record, items) do
    List.foldl(items, %{}, fn (n, acc) -> 
      case n["type"] do
        "date" -> 
          date = String.split(record[n["name"]], "-")
          Map.merge(acc, %{n["name"] => Map.new(Enum.zip([:year, :month, :day], date))})
        _ -> Map.merge(acc, %{n["name"] => record[n["name"]]})

      end

    end)
  end

  def record_create(conn, %{"id" => id}) do
    class = Repo.get!(Class, id)
    items = class.config
    {:ok, items} = JSON.decode(items)
    records = class.record
    {:ok, records} = JSON.decode(records)
    record = conn.params["new_record"]
    record = date_format(record, items)

    IO.inspect record

    records = Enum.reverse([record | Enum.reverse(records)])
    IO.inspect records
    {:ok, records} = JSON.encode(records)
    changeset = Class.changeset(class, %{"record" => records})

    items = class.config
    {:ok, items} = JSON.decode(items)

    case Repo.update(changeset) do
      {:ok, class} ->
        conn
        |> put_flash(:info, "Record created successfully.")
        |> redirect(to: class_path(conn, :show, class))
      {:error, _changeset} ->
        render(conn, "record_new.html", class: class, items: items)
    end

  end

  defp date_before(l1, l2) do
    l = Enum.filter(Enum.zip(l1, l2), fn {a,b} -> a != b end)
    case l do
      [] -> true
      [{a,b}] when a < b -> true
      [{a,b}, _] when a < b -> true
      _ -> false   
    end
  end

  defp date_after(l1, l2) do
    l = Enum.filter(Enum.zip(l1, l2), fn {a,b} -> a != b end)
    case l do
      [] -> true
      [{a,b}] when a > b -> true
      [{a,b}, _] when a > b -> true
      _ -> false   
    end
    
  end

  defp date_equal(l1, l2) do
    Enum.all?(Enum.zip(l1, l2), fn {a,b} -> a == b end)
  end

  defp check(x, s, "sel") do
    s = String.split(s, ",")
    Enum.find(s, false, fn a -> a == x end)
  end

  defp check(x, s, "date") do
    # x cannot be ""
    s = String.split(s, ",")
    x = Enum.map(String.split(x, "-"), &(String.to_integer(&1)))
    case s do
      ["",""] -> false
      ["", b] -> 
        try do
          Enum.map(String.split(b, "-"), &(String.to_integer(&1)))
        rescue
          _ -> false
        else
          b -> date_before(x, b)
        end
      [a, ""] -> 
        try do
          Enum.map(String.split(a, "-"), &(String.to_integer(&1)))
        rescue
          _ -> false
        else
          a -> date_after(x, a)
        end
      [a,  b] ->
        try do
          {Enum.map(String.split(a, "-"), &(String.to_integer(&1))), Enum.map(String.split(b, "-"), &(String.to_integer(&1)))} 
        rescue
          _ -> false
        else
          {a, b} -> date_after(x, a) and date_before(x, b)
        end
      [""] -> true
      [c] ->
        try do
          Enum.map(String.split(c, "-"), &(String.to_integer(&1)))
        rescue
          _ -> false
        else
          c -> date_equal(x, c)
        end
      _ -> false        
    end
  end

  defp check(x, s, "str") do
    x = String.downcase(x)
    s = String.downcase(s)

    case s do
      "" -> true
      _ -> String.contains?(x, s)   
    end
  end

  defp check(x, s, "int") do
    s = String.split(s, ",")
    case {x, s} do
      {"", [""]} -> true
      {"", _} -> false
      _ -> 
        x = String.to_integer(x)
        case s do
          ["",""] -> false
          ["", b] -> 
            try do
              String.to_integer(b)
            rescue
              _ -> false
            else
              b -> x <= b 
            end
          [a, ""] -> 
            try do
              String.to_integer(a)
            rescue
              _ -> false
            else
              a -> x >= a
            end
          [a,  b] ->
            try do
              {String.to_integer(a), String.to_integer(b)} 
            rescue
              _ -> false
            else
              {a, b} -> x >= a and x <= b 
            end
          [""] -> true
          [c] ->
            try do
              String.to_integer(c)
            rescue
              _ -> false
            else
              c -> x == c
            end
          _ -> false        
        end
    end    
  end

  def show(conn, %{"id" => id}) do
    class = Repo.get!(Class, id)
    name = class.name
    items = class.config
    records = class.record
    {:ok, items} = JSON.decode(items)
    {:ok, records} = JSON.decode(records)

    s = conn.params["search"]

    IO.inspect s

    records = 
    case s do
      nil ->     
        records
      _ ->
        Enum.filter(records, fn x -> Enum.find((for item <- items, do: check(x[item["name"]], s[item["name"]], item["type"])), true, &(!&1)) end)        
    end


    a_s = 
    for n <- items do
      case n["type"] do
        "int" ->
          col = Enum.filter(Enum.map(records, &(Map.get(&1, n["name"]))), fn x -> x != "" end) |> Enum.map(&(String.to_integer(&1)))
          case col do
            [] -> ""
            _ -> 
            c = Enum.count(col)
            s = Enum.sum(col)
            a = Float.to_string(s/c,  [decimals: 1, compact: true])
            s = Integer.to_string(s)
            a <> "/" <> s              
          end
        _ -> ""
      end
    end

    items = Enum.map(items, &(Map.get(&1, "name")))
    render(conn, "show.html", class: class, name: name, items: items, records: records, a_s: a_s)


  end

  def edit(conn, %{"id" => id}) do
    class = Repo.get!(Class, id)
    changeset = Class.changeset(class)
    render(conn, "edit.html", class: class, changeset: changeset)
  end

  def record_edit(conn, %{"id" => id, "record" => record}) do
    class = Repo.get!(Class, id)
    items = class.config
    {:ok, items} = JSON.decode(items)
    record = format_date(record, items)
    render(conn, "record_edit.html", class: class, items: items, record: record)
  end

  def update(conn, %{"id" => id, "class" => class_params}) do
    class = Repo.get!(Class, id)
    changeset = Class.changeset(class, class_params)

    case Repo.update(changeset) do
      {:ok, class} ->
        conn
        |> put_flash(:info, "Class updated successfully.")
        |> redirect(to: class_path(conn, :show, class))
      {:error, changeset} ->
        render(conn, "edit.html", class: class, changeset: changeset)
    end
  end

  def record_update(conn, %{"id" => id, "record" => record}) do
    class = Repo.get!(Class, id)
    items = class.config
    {:ok, items} = JSON.decode(items)
    records = class.record
    {:ok, records} = JSON.decode(records)

    edit_record = conn.params["edit_record"]

    record = date_format(record, items)
    edit_record = date_format(edit_record, items)

    i = Enum.find_index(records, fn x -> x == record end)
    records = List.replace_at(records, i, edit_record)    

    IO.inspect records
    {:ok, records} = JSON.encode(records)
    changeset = Class.changeset(class, %{"record" => records})

    case Repo.update(changeset) do
      {:ok, class} ->
        conn
        |> put_flash(:info, "Record updated successfully.")
        |> redirect(to: class_path(conn, :show, class))
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Record cannot be updated.")
        |> redirect(to: class_path(conn, :show, class))
    end
    
  end

  def delete(conn, %{"id" => id}) do
    class = Repo.get!(Class, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(class)

    conn
    |> put_flash(:info, "Class deleted successfully.")
    |> redirect(to: class_path(conn, :index))
  end

  def record_delete(conn, %{"id" => id, "record" => record}) do
    class = Repo.get!(Class, id)
    records = class.record
    {:ok, records} = JSON.decode(records)
    # records = Enum.filter(records, fn x -> x != record end)
    records = List.delete(records, record)
    IO.inspect records
    {:ok, records} = JSON.encode(records)
    changeset = Class.changeset(class, %{"record" => records})  

    case Repo.update(changeset) do
      {:ok, class} ->
        conn
        |> put_flash(:info, "Record deleted successfully.")
        |> redirect(to: class_path(conn, :show, class))
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Record cannot be deleted.")
        |> redirect(to: class_path(conn, :show, class))
    end
    
  end

  defp csv_content(list) do
    list 
    |> CSV.encode
    |> Enum.to_list
    |> to_string    
  end

  def export(conn, %{"id" => id}) do
    class = Repo.get!(Class, id)
    name = class.name
    items = class.config
    records = class.record
    {:ok, items} = JSON.decode(items)
    items = Enum.map(items, &(Map.get(&1, "name")))
    {:ok, records} = JSON.decode(records)
    records = Enum.map(records, fn x -> for n <- items, do: x[n] end)
    list = [items | records]

    arg = "attachment; filename=\"" <> name <> ".csv\""

    conn
    |> put_flash(:info, "Class exported successfully.")
    |> put_resp_content_type("text/csv")
    |> put_resp_header("Content-Disposition", arg)
    |> send_resp(200, csv_content(list))
    |> halt
  end

  def import_new(conn, %{"id" => id}) do
    class = Repo.get!(Class, id)
    render(conn, "import_new.html", class: class)
  end

  defp test(h, x, items) do
    item = Enum.find(items, fn x -> x["name"] == h end)
    case item["type"] do
      "str" -> {h, x}
      "int" ->
        case x do
          "" -> {h, x}
          _ -> 
            try do
              String.to_integer(x)
            rescue
              _ -> 
                false
            else
              _ -> {h, x}
            end
        end
      "date" ->
        case x do
          "" -> {h, x}
          _ ->
            try do
              date = String.split(x, "-")
              [y, m, d] = Enum.map(date, &(String.to_integer(&1)))
              {{year,month,day},_} = :erlang.localtime()
              y1 = year - 5
              y2 = year + 5
              [true, true, true] = [y1 <= y and y <= y2, 1 <= m and m <= 12, 1 <= d and d <= 31]
              [yy, mm, dd] = [Integer.to_string(y), Integer.to_string(m), Integer.to_string(d)]
              yy <> "-" <> mm <> "-" <> dd
            rescue
              _ ->
                false
            else
              v -> {h, v}
            end
        end
      "sel" ->
        case x do
          "" -> {h, x}
          _ -> 
            sel = String.split(item["select"], ",")
            case Enum.any?(sel, fn it -> x == it end) do
              true -> {h, x}
              false -> 
                false
            end
        end
    end
  end


  def import_create(conn, %{"id" => id}) do
    class = Repo.get!(Class, id)
    items = class.config
    records = class.record
    {:ok, items} = JSON.decode(items)
    {:ok, records} = JSON.decode(records)
    try do
      file = conn.params["csv"]["file"]
      path = file.path
      path
      |> File.stream!
      |> CSV.decode
      |> Enum.to_list
    rescue
      _ ->
        conn
        |> put_flash(:error, "Invalid file.")
        |> redirect(to: class_path(conn, :import_new, class))
    else
      list ->
        header = Enum.at(list, 0)
        body = Enum.drop(list, 1)
        if is_nil(header) or Enum.empty?(body) do
          conn
          |> put_flash(:error, "No data in the file.")
          |> redirect(to: class_path(conn, :import_new, class))
        end

        names = Enum.map(items, &(Map.get(&1, "name")))
        flag = Enum.all?(header, fn x -> Enum.any?(names, fn y -> y == x end) end)
        if !flag do
          conn
          |> put_flash(:error, "Invalid header of the data.")
          |> redirect(to: class_path(conn, :import_new, class))
        end
        values = body
        |> Enum.map(&(Enum.zip(header, &1)))
        |> Enum.map(&(Enum.map(&1, fn {h, x} -> test(h, x, items) end)))
        |> Enum.filter(&(Enum.all?(&1)))
        |> Enum.map(&(Map.new(&1)))

        IO.inspect values

        records = Enum.concat(records, values)

        IO.inspect records
        {:ok, records} = JSON.encode(records)
        changeset = Class.changeset(class, %{"record" => records})

        case Repo.update(changeset) do
          {:ok, class} ->
            conn
            |> put_flash(:info, "Record imported successfully.")
            |> redirect(to: class_path(conn, :show, class))
          {:error, _changeset} ->
            conn
            |> put_flash(:error, "Record cannot be imported.")
            |> redirect(to: class_path(conn, :show, class))
        end

    end

    
  end

end
