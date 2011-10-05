
class PlastronicsDB < RStore::BaseDB
  connect :adapter => 'mysql', 
    :host     => 'localhost',
    :user     => 'root',
    :password => 'xxx'

end


class MyDB < RStore::BaseDB
end

