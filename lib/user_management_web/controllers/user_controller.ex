defmodule UserManagementWeb.UserController do
  use UserManagementWeb, :controller

  alias UserManagement.Accounts
  alias UserManagement.Accounts.User
  alias UserManagement.Guardian

  action_fallback UserManagementWeb.FallbackController

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.json", users: users)
  end

  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Accounts.create_user(user_params),
         {:ok, token, _claims} <- Guardian.encode_and_sign(user) do
      conn |> render("jwt.json", jwt: token)
    end
  end

  def sign_in(conn, %{"username" => username, "password" => password}) do
    case Accounts.token_sign_in(username, password) do
      {:ok, token, _claims} ->
        conn |> render("jwt.json", jwt: token)
      _ ->
        {:error, :unauthorized}
    end
  end

#  def show(conn, %{"id" => id}) do
#    user = Accounts.get_user!(id)
#    render(conn, "show.json", user: user)
#  end

  def show(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    conn |> render("user.json", user: user)
  end

  def update_profile(conn, %{"user" => user_params}) do
    user = Guardian.Plug.current_resource(conn)

    with {:ok, %User{} = user} <- Accounts.update_user_profile(user, user_params) do
      #render(conn, "show.json", user: user)
      conn |> render("user.json", user: user)
    end
  end

  def update_password(conn, %{"old_password" => old_password,"user" => user_params}) do
    user = Guardian.Plug.current_resource(conn)

    with {:ok, %User{} = user} <- Accounts.update_user_password(user, user_params, old_password) do
      conn |> render("user.json", user: user)
    end
  end

  def delete(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    with {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end
end
