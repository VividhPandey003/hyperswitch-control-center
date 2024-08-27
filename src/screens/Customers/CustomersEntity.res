open CustomersType

let defaultColumns = [
  CustomerId,
  Name,
  Email,
  PhoneCountryCode,
  Phone,
  Description,
  Address,
  CreatedAt,
]

let allColumns = [CustomerId, Name, Email, Phone, PhoneCountryCode, Description, Address, CreatedAt]

let getHeading = colType => {
  switch colType {
  | CustomerId => Table.makeHeaderInfo(~key="customer_id", ~title="Customer Id", ~showSort=true)
  | Name => Table.makeHeaderInfo(~key="name", ~title="Customer Name", ~showSort=true)
  | Email => Table.makeHeaderInfo(~key="email", ~title="Email", ~showSort=true)
  | PhoneCountryCode =>
    Table.makeHeaderInfo(~key="phone_country_code", ~title="Phone Country Code", ~showSort=true)
  | Phone => Table.makeHeaderInfo(~key="phone", ~title="Phone", ~showSort=true)
  | Description => Table.makeHeaderInfo(~key="description", ~title="Description", ~showSort=true)
  | Address => Table.makeHeaderInfo(~key="address", ~title="Address", ~showSort=true)
  | CreatedAt => Table.makeHeaderInfo(~key="created_at", ~title="Created", ~showSort=true)
  }
}

let getCell = (customersData, colType): Table.cell => {
  switch colType {
  | CustomerId =>
    CustomCell(
      <HSwitchOrderUtils.CopyLinkTableCell
        url={`/customers/${customersData.customer_id}`}
        displayValue={customersData.customer_id}
        copyValue={Some(customersData.customer_id)}
      />,
      "",
    )
  | Name => Text(customersData.name)
  | Email => Text(customersData.email)
  | Phone => Text(customersData.phone)
  | PhoneCountryCode => Text(customersData.phone_country_code)
  | Description => Text(customersData.description)
  | Address => Date(customersData.address)
  | CreatedAt => Date(customersData.created_at)
  }
}

let itemToObjMapper = dict => {
  open LogicUtils
  {
    customer_id: dict->getString("customer_id", ""),
    name: dict->getString("name", ""),
    email: dict->getString("email", ""),
    phone: dict->getString("phone", ""),
    phone_country_code: dict->getString("phone_country_code", ""),
    description: dict->getString("description", ""),
    address: dict->getString("address", ""),
    created_at: dict->getString("created_at", ""),
    metadata: dict->getJsonObjectFromDict("metadata"),
  }
}

let getCustomers: JSON.t => array<customers> = json => {
  open LogicUtils
  getArrayDataFromJson(json, itemToObjMapper)
}

let customersEntity = EntityType.makeEntity(
  ~uri="",
  ~getObjects=getCustomers,
  ~defaultColumns,
  ~allColumns,
  ~getHeading,
  ~getCell,
  ~dataKey="",
  ~getShowLink={
    customerData => GlobalVars.appendDashboardPath(~url=`/customers/${customerData.customer_id}`)
  },
)
