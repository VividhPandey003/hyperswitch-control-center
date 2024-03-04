open ProviderTypes

let itemIntegrationDetailsMapper = dict => {
  open LogicUtils
  {
    is_done: dict->getBool("is_done", false),
    metadata: dict->getDictfromDict("metadata")->JSON.Encode.object,
  }
}

let itemToObjMapper = dict => {
  open LogicUtils
  {
    pricing_plan: dict->getDictfromDict("pricing_plan")->itemIntegrationDetailsMapper,
    connector_integration: dict
    ->getDictfromDict("connector_integration")
    ->itemIntegrationDetailsMapper,
    integration_checklist: dict
    ->getDictfromDict("integration_checklist")
    ->itemIntegrationDetailsMapper,
    account_activation: dict->getDictfromDict("account_activation")->itemIntegrationDetailsMapper,
  }
}

let getIntegrationDetails: JSON.t => integrationDetailsType = json => {
  open LogicUtils
  json->getDictFromJsonObject->itemToObjMapper
}

let itemToObjMapperForEnum: Js.Dict.t<Js.Json.t> => UserManagementTypes.permissions = dict => {
  open LogicUtils
  {
    enum_name: getString(dict, "enum_name", ""),
    description: getString(dict, "description", ""),
    isPermissionAllowed: false,
  }
}

let itemToObjMapperForGetInfo: Js.Dict.t<Js.Json.t> => UserManagementTypes.getInfoType = dict => {
  open LogicUtils
  {
    module_: getString(dict, "group", ""),
    description: getString(dict, "description", ""),
    permissions: getArrayFromDict(dict, "permissions", [])->Array.map(i =>
      i->getDictFromJsonObject->itemToObjMapperForEnum
    ),
    isPermissionAllowed: false,
  }
}

let getDefaultValueOfEnum: UserManagementTypes.permissions = {
  {
    enum_name: "",
    description: "",
    isPermissionAllowed: false,
  }
}
