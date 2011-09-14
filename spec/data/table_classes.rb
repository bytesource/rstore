class ProjectTable < CSVStore::BaseTable

  create do
    primary_key :id, :allow_null => false
    Integer     :item
    String      :description
    Float       :price
  end

end


class DNATable < CSVStore::BaseTable
end

