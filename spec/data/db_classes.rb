
class PlastronicsDB < CSVStore::BaseDB
  connect :database => 'mysql', :password => 'xxx'
end


class MyDB < CSVStore::BaseDB
end

