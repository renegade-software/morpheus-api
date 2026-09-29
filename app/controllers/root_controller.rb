# Public landing page for the API root: a Matrix-style page for browsers, the plain banner for curl.
# It inherits from ActionController::API, not ApplicationController, so it never requires a Clerk session.
class RootController < ActionController::API
  BANNER = <<~'TEXT'
     __  __  ___  ____  ____  _   _ _____ _   _ ____
    |  \/  |/ _ \|  _ \|  _ \| | | | ____| | | / ___|
    | |\/| | | | | |_) | |_) | |_| |  _| | | | \___ \
    | |  | | |_| |  _ <|  __/|  _  | |___| |_| |___) |
    |_|  |_|\___/|_| \_\_|   |_| |_|_____|\___/|____/

    Wake up, Neo...
  TEXT

  PAGE = Rails.root.join("app/views/root/show.html").read.html_safe

  def show
    if request.format.html?
      render html: PAGE
    else
      render plain: BANNER
    end
  end
end
