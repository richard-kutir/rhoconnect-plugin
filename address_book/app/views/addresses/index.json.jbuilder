json.array!(@addresses) do |address|
  json.extract! address, :id, :name, :address, :email
  json.url address_url(address, format: :json)
end
