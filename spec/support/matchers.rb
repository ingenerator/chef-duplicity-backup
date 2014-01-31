# Custom matchers for resources that don't define their own
def grant_mysql_database_user(username)
  ChefSpec::Matchers::ResourceMatcher.new(:mysql_database_user, :grant, username)
end