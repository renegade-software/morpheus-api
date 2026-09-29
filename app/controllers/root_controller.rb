# Public landing text for the API root. It inherits from ActionController::API, not
# ApplicationController, so it never requires a Clerk session.
class RootController < ActionController::API
  BANNER = <<~'TEXT'
     __  __  ___  ____  ____  _   _ _____ _   _ ____
    |  \/  |/ _ \|  _ \|  _ \| | | | ____| | | / ___|
    | |\/| | | | | |_) | |_) | |_| |  _| | | | \___ \
    | |  | | |_| |  _ <|  __/|  _  | |___| |_| |___) |
    |_|  |_|\___/|_| \_\_|   |_| |_|_____|\___/|____/

           .  *        you are awake.        *  .
                  the API is too.

      GET /up      health check
      GET /user    who you are (needs a Clerk session)
  TEXT

  def show
    render plain: BANNER
  end
end
