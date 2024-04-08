open SwitchMerchantUtils

type columns =
  | MerchantName
  | RoleName
  | Actions

let visibleColumns = [MerchantName, RoleName, Actions]

let defaultColumns = [MerchantName, RoleName, Actions]

let allColumns = [MerchantName, RoleName, Actions]

let itemToObjMapper = dict => {
  open LogicUtils
  {
    merchant_id: getString(dict, "merchant_id", ""),
    merchant_name: getString(dict, "merchant_name", ""),
    is_active: getBool(dict, "is_active", false),
    role_id: getString(dict, "role_id", ""),
    role_name: getString(dict, "role_name", "ROLENAME"),
    org_id: getString(dict, "org_id", ""),
  }
}

let getItems: JSON.t => array<switchMerchantListResponse> = json => {
  LogicUtils.getArrayDataFromJson(json, itemToObjMapper)
}

let getHeading = colType => {
  switch colType {
  | MerchantName => Table.makeHeaderInfo(~key="merchant_name", ~title="Merchant Name", ())
  | RoleName => Table.makeHeaderInfo(~key="role", ~title="Role", ())
  | Actions => Table.makeHeaderInfo(~key="actions", ~title="Actions", ())
  }
}

let getCell = (item: switchMerchantListResponse, colType): Table.cell => {
  switch colType {
  | MerchantName => Text(item.merchant_name)
  | RoleName =>
    CustomCell(
      <div className="flex flex-row gap-2">
        <Icon name="user" className="text-jp-gray-700" size=12 />
        <span> {"role"->React.string} </span>
      </div>,
      "",
    )
  | Actions => CustomCell(<Icon name="plus" className="text-jp-gray-700" size=12 />, "")
  }
}

let merchantTableEntity = () =>
  EntityType.makeEntity(
    ~uri="",
    ~getObjects=getItems,
    ~defaultColumns,
    ~allColumns,
    ~getHeading,
    ~dataKey="",
    ~getCell,
    (),
  )
