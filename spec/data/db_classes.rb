
class PlastronicsDB < RStore::BaseDB
  info(:adapter => 'mysql', 
       :host     => 'localhost',
       :user     => 'root',
       :password => 'xxx')

end


class MyDB < RStore::BaseDB
end

