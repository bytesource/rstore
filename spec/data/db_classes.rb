
class PlastronicsDB < RStore::BaseDB
  connect :adapter => 'mysql', :password => 'xxx'
end


class MyDB < RStore::BaseDB
end

