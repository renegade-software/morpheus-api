# Keep the health check independent of Clerk: a Clerk outage or config mistake must not make
# Render think the API is down. Neither /up nor the public root banner needs to know who is asking.
Clerk.configure do |c|
  c.excluded_routes = [ "/", "/up" ]
end
