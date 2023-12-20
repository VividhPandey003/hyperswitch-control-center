let h3Leading2TextClass = `${HSwitchUtils.getTextClass(
    ~textVariant=H3,
    ~h3TextVariant=Leading_2,
    (),
  )} text-grey-700`
let p1RegularTextClass = `${HSwitchUtils.getTextClass(
    ~textVariant=P1,
    ~paragraphTextVariant=Regular,
    (),
  )} text-grey-700 opacity-50`

let p1MediumTextClass = `${HSwitchUtils.getTextClass(
    ~textVariant=P1,
    ~paragraphTextVariant=Medium,
    (),
  )} text-grey-700`
let p2RedularTextClass = `${HSwitchUtils.getTextClass(
    ~textVariant=P2,
    ~paragraphTextVariant=Regular,
    (),
  )} text-grey-700 opacity-50`

let preRequisiteList = [
  "You need to grant all the permissions to create and receive payments",
  "Confirm your email id once PayPal sends you the mail",
]

module PayPalCreateNewAccountModal = {
  @react.component
  let make = (~butttonDisplayText, ~actionUrl) => {
    React.useEffect0(() => {
      Window.payPalCreateAccountWindow()
      None
    })

    <button
      className="!w-fit rounded-md bg-blue-700 text-white py-2 h-fit border px-6 flex items-center justify-center gap-2"
      onClick={e => {
        e->ReactEvent.Mouse.stopPropagation
      }}>
      <AddDataAttributes attributes=[("data-paypal-button", "true")]>
        <a href={`${actionUrl}&displayMode=minibrowser`} target="PPFrame">
          {butttonDisplayText->React.string}
        </a>
      </AddDataAttributes>
      <Icon name="thin-right-arrow" size=20 />
    </button>
  }
}
module ManualSetupScreen = {
  @react.component
  let make = (
    ~isUpdateFlow,
    ~connector,
    ~connectorAccountFields,
    ~selectedConnector,
    ~connectorMetaDataFields,
    ~connectorWebHookDetails,
    ~configuartionType,
    ~connectorLabelDetailField,
  ) => {
    let setupAccountStatus = Recoil.useRecoilValueFromAtom(PayPalFlowUtils.paypalAccountStatusAtom)
    let bodyType = isUpdateFlow->PayPalFlowUtils.getBodyType(configuartionType, setupAccountStatus)

    <div className="flex flex-col gap-8">
      <ConnectorAccountDetailsHelper.ConnectorConfigurationFields
        connector={connector->ConnectorUtils.getConnectorNameTypeFromString}
        connectorAccountFields
        selectedConnector
        connectorMetaDataFields
        connectorWebHookDetails
        bodyType
        connectorLabelDetailField
      />
    </div>
  }
}

module LandingScreen = {
  @react.component
  let make = (~configuartionType, ~setConfigurationType) => {
    let getBlockColor = value =>
      configuartionType === value ? "border border-blue-700 bg-blue-700 bg-opacity-10 " : "border"

    <div className="flex flex-col gap-10">
      <div className="flex flex-col gap-4">
        <p className=h3Leading2TextClass>
          {"Do you have a PayPal business account?"->React.string}
        </p>
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2 md:gap-8">
          {PayPalFlowUtils.listChoices
          ->Js.Array2.mapi((items, index) => {
            <div
              key={index->string_of_int}
              className={`p-6 flex flex-col gap-4 rounded-md cursor-pointer ${items.variantType->getBlockColor} rounded-md`}
              onClick={_ => setConfigurationType(_ => items.variantType)}>
              <div className="flex justify-between items-center">
                <div className="flex gap-2 items-center ">
                  <p className=p1MediumTextClass> {items.displayText->React.string} </p>
                </div>
                <Icon
                  name={configuartionType === items.variantType ? "selected" : "nonselected"}
                  size=20
                  className="cursor-pointer !text-blue-800"
                />
              </div>
              <div className="flex gap-2 items-center ">
                <p className=p1RegularTextClass> {items.choiceDescription->React.string} </p>
              </div>
            </div>
          })
          ->React.array}
        </div>
      </div>
    </div>
  }
}
module RedirectionToPayPalFlow = {
  @react.component
  let make = (~actionUrl, ~setActionUrl, ~connectorId, ~getStatus) => {
    open APIUtils

    let url = RescriptReactRouter.useUrl()
    let path = url.path->Belt.List.toArray->Js.Array2.joinWith("/")
    let updateDetails = useUpdateMethod(~showErrorToast=false, ())
    let (screenState, setScreenState) = React.useState(_ => PageLoaderWrapper.Loading)

    let getRedirectPaypalWindowUrl = async _ => {
      open LogicUtils
      try {
        setScreenState(_ => PageLoaderWrapper.Loading)
        let returnURL = `${HSwitchGlobalVars.hyperSwitchFEPrefix}/${path}?${url.search}&is_back=true`
        Js.log2("returnURLreturnURL", returnURL)
        let body =
          [
            ("connector", "paypal"->Js.Json.string),
            ("return_url", returnURL->Js.Json.string),
            ("connector_id", connectorId->Js.Json.string),
          ]
          ->Js.Dict.fromArray
          ->Js.Json.object_
        let url = `${getURL(~entityName=PAYPAL_ONBOARDING, ~methodType=Post, ())}/action_url`

        let response = await updateDetails(url, body, Post)
        let actionURL =
          response->getDictFromJsonObject->getDictfromDict("paypal")->getString("action_url", "")
        setActionUrl(_ => actionURL)
        setScreenState(_ => PageLoaderWrapper.Success)
      } catch {
      | _ => setScreenState(_ => PageLoaderWrapper.Error(""))
      }
    }

    React.useEffect0(() => {
      getRedirectPaypalWindowUrl()->ignore
      None
    })
    <PageLoaderWrapper screenState>
      <div className="flex flex-col gap-6">
        <p className=h3Leading2TextClass>
          {"Sign in / Sign up to auto-configure your credentials & webhooks"->React.string}
        </p>
        <div className="flex flex-col gap-2">
          <p className={`${p1RegularTextClass} !opacity-100`}>
            {"Things to keep in mind while signing up"->React.string}
          </p>
          {preRequisiteList
          ->Js.Array2.mapi((item, index) =>
            <p className=p1RegularTextClass>
              {`${(index + 1)->string_of_int}. ${item}`->React.string}
            </p>
          )
          ->React.array}
        </div>
        <div className="flex gap-4 items-center">
          <PayPalCreateNewAccountModal actionUrl butttonDisplayText="Sign in / Sign up on PayPal" />
          <p
            className={`${p1RegularTextClass} !text-blue-700 !opacity-80 cursor-pointer`}
            onClick={_ => getStatus()->ignore}>
            {"Refresh Status"->React.string}
          </p>
        </div>
      </div>
    </PageLoaderWrapper>
  }
}

module ErrorPage = {
  @react.component
  let make = (~setupAccountStatus, ~actionUrl, ~getStatus) => {
    let errorPageDetails = setupAccountStatus->PayPalFlowUtils.getPageDetailsForAutomatic

    <div className="flex flex-col gap-6">
      <div className="flex flex-col gap-6 p-8 bg-jp-gray-light_gray_bg">
        <Icon name="error-icon" size=24 />
        <div className="flex flex-col gap-2">
          <UIUtils.RenderIf condition={errorPageDetails.headerText->Js.String2.length > 0}>
            <p className={`${p1RegularTextClass} !opacity-100`}>
              {errorPageDetails.headerText->React.string}
            </p>
          </UIUtils.RenderIf>
          <UIUtils.RenderIf condition={errorPageDetails.subText->Js.String2.length > 0}>
            <p className=p1RegularTextClass> {errorPageDetails.subText->React.string} </p>
          </UIUtils.RenderIf>
        </div>
        <UIUtils.RenderIf condition={errorPageDetails.buttonText->Belt.Option.isSome}>
          <PayPalCreateNewAccountModal
            butttonDisplayText={errorPageDetails.buttonText->Belt.Option.getWithDefault("")}
            actionUrl
          />
        </UIUtils.RenderIf>
        <UIUtils.RenderIf condition={errorPageDetails.additionalInformation->Belt.Option.isSome}>
          <p className={`${p1RegularTextClass} !opacity-100`}>
            {`->  ${errorPageDetails.additionalInformation->Belt.Option.getWithDefault(
                "",
              )}`->React.string}
          </p>
        </UIUtils.RenderIf>
      </div>
      <UIUtils.RenderIf condition={errorPageDetails.refreshStatusText->Belt.Option.isSome}>
        <div className="flex gap-2">
          <p className=p1RegularTextClass>
            {errorPageDetails.refreshStatusText->Belt.Option.getWithDefault("")->React.string}
          </p>
          <p
            className={`${p1RegularTextClass} !text-blue-700 !opacity-80 cursor-pointer`}
            onClick={_ => getStatus()->ignore}>
            {"Refresh Status"->React.string}
          </p>
        </div>
      </UIUtils.RenderIf>
    </div>
  }
}

external toJson: 'a => Js.Json.t = "%identity"

@react.component
let make = (
  ~connector,
  ~connectorAccountFields,
  ~selectedConnector,
  ~connectorMetaDataFields,
  ~connectorWebHookDetails,
  ~isUpdateFlow,
  ~setInitialValues,
  ~handleConnectorConnected,
  ~initialValues,
  ~setShowModal,
  ~showVerifyModal,
  ~setShowVerifyModal,
  ~verifyErrorMessage,
  ~setVerifyDone,
  ~handleStateToNextPage,
  ~connectorLabelDetailField,
) => {
  open APIUtils

  let url = RescriptReactRouter.useUrl()
  let showToast = ToastState.useShowToast()

  let connectorValue = isUpdateFlow
    ? url.path->Belt.List.toArray->Belt.Array.get(1)->Belt.Option.getWithDefault("")
    : url.search
      ->LogicUtils.getDictFromUrlSearchParams
      ->Js.Dict.get("connectorId")
      ->Belt.Option.getWithDefault("")

  let (connectorId, setConnectorId) = React.useState(_ => connectorValue)
  let updateDetails = useUpdateMethod(~showErrorToast=false, ())
  let isRedirectedFromPaypalModal =
    url.search
    ->LogicUtils.getDictFromUrlSearchParams
    ->Js.Dict.get("is_back")
    ->Belt.Option.getWithDefault("")
    ->LogicUtils.getBoolFromString(false)

  let (screenState, setScreenState) = React.useState(_ => PageLoaderWrapper.Success)
  let (configuartionType, setConfigurationType) = React.useState(_ => PayPalFlowTypes.NotSelected)
  let (actionUrl, setActionUrl) = React.useState(_ => "")

  let (setupAccountStatus, setSetupAccountStatus) = Recoil.useRecoilState(
    PayPalFlowUtils.paypalAccountStatusAtom,
  )
  let (suggestedAction, suggestedActionExists) = ConnectorUtils.getSuggestedAction(
    ~verifyErrorMessage,
    ~connector,
  )

  let onSubmitMain = async values => {
    open ConnectorUtils
    open PayPalFlowUtils
    try {
      setScreenState(_ => Loading)
      let profileIdValue =
        values->LogicUtils.getDictFromJsonObject->LogicUtils.getString("profile_id", "")
      let body = generateConnectorPayloadPayPal(
        ~profileId=profileIdValue,
        ~connectorId,
        ~connector,
        ~isUpdateFlow,
        ~configuartionType,
        ~setupAccountStatus,
        ~connectorLabel={
          values->LogicUtils.getDictFromJsonObject->LogicUtils.getString("connector_label", "")
        },
      )

      let url = getURL(
        ~entityName=CONNECTOR,
        ~methodType=Post,
        ~id=isUpdateFlow ? Some(connectorId) : None,
        (),
      )
      let res = await updateDetails(url, body, Post)

      setInitialValues(_ => res)
      let connectorId =
        res->LogicUtils.getDictFromJsonObject->LogicUtils.getString("merchant_connector_id", "")
      if !isUpdateFlow {
        RescriptReactRouter.push(`/connectors/new?name=payPal&connectorId=${connectorId}`)
      }
      setConnectorId(_ => connectorId)
      setScreenState(_ => Success)
    } catch {
    | Js.Exn.Error(e) => {
        setShowVerifyModal(_ => false)
        setVerifyDone(_ => ConnectorTypes.NoAttempt)
        switch Js.Exn.message(e) {
        | Some(message) => {
            let errMsg = message->parseIntoMyData
            if errMsg.code->Belt.Option.getWithDefault("")->Js.String2.includes("HE_01") {
              showToast(
                ~message="This configuration already exists for the connector. Please try with a different country or label under advanced settings.",
                ~toastType=ToastState.ToastError,
                (),
              )
              // setCurrentStep(_ => IntegFields)
              setScreenState(_ => Success)
            } else {
              showToast(
                ~message="Failed to Save the Configuration!",
                ~toastType=ToastState.ToastError,
                (),
              )
              setScreenState(_ => Error(message))
            }
          }

        | None => setScreenState(_ => Error("Failed to Fetch!"))
        }
        Js.Exn.raiseError("Failed to Fetch!")
      }
    }
  }

  let getStatus = async () => {
    open PayPalFlowUtils
    try {
      setScreenState(_ => PageLoaderWrapper.Loading)
      let profileId =
        initialValues->LogicUtils.getDictFromJsonObject->LogicUtils.getString("profile_id", "")
      let responseValue = await paypalAPICall(~updateDetails, ~connectorId, ~profileId)
      switch responseValue->Js.Json.classify {
      | JSONString(str) => setSetupAccountStatus(._ => str->PayPalFlowUtils.stringToVariantMapper)
      | JSONObject(dict) =>
        handleObjectResponse(
          ~dict,
          ~setSetupAccountStatus,
          ~setInitialValues,
          ~connector,
          ~handleStateToNextPage,
        )
      | _ => ()
      }
      setScreenState(_ => PageLoaderWrapper.Success)
    } catch {
    | _ => setScreenState(_ => PageLoaderWrapper.Error(""))
    }
  }

  React.useEffect0(() => {
    if isRedirectedFromPaypalModal {
      getStatus()->ignore
    }
    setSetupAccountStatus(._ => Account_not_found)
    None
  })

  let validateMandatoryFieldForPaypal = values => {
    let errors = Js.Dict.empty()
    let valuesFlattenJson = values->JsonFlattenUtils.flattenObject(true)
    let profileId = valuesFlattenJson->LogicUtils.getString("profile_id", "")
    if profileId->Js.String2.length === 0 {
      Js.Dict.set(errors, "Profile Id", `Please select your business profile`->Js.Json.string)
    }
    errors->Js.Json.object_
  }

  let handleConnector = async values => {
    try {
      await onSubmitMain(values)
      setSetupAccountStatus(._ => Redirecting_to_paypal)
    } catch {
    | Js.Exn.Error(e) => ()
    }
  }

  let handleOnSubmit = (values, _) => {
    switch setupAccountStatus {
    | Account_not_found =>
      switch configuartionType {
      | Manual
      | NotSelected =>
        setSetupAccountStatus(._ => Manual_setup_flow)

      | Automatic => handleConnector(values)->ignore
      }
    | Manual_setup_flow => {
        let dictOfInitialValues = values->LogicUtils.getDictFromJsonObject
        dictOfInitialValues->Js.Dict.set("disabled", false->Js.Json.boolean)
        dictOfInitialValues->Js.Dict.set("status", "active"->Js.Json.string)
        setInitialValues(_ => dictOfInitialValues->Js.Json.object_)
        handleConnectorConnected(dictOfInitialValues->Js.Json.object_)
      }
    | _ => ()
    }
    Js.Nullable.null->Js.Promise.resolve
  }

  <div className="w-full h-full flex flex-col justify-between">
    <PageLoaderWrapper screenState>
      <Form initialValues validate={validateMandatoryFieldForPaypal} onSubmit={handleOnSubmit}>
        <div className="">
          <ConnectorAccountDetailsHelper.ConnectorHeaderWrapper
            connector
            headerButton={<FormRenderer.SubmitButton
              loadingText="Processing..."
              text="Proceed"
              disabledParamter={configuartionType === NotSelected ? true : false}
            />}
            setShowModal>
            <div className="flex flex-col gap-2 p-2 md:p-10">
              {switch setupAccountStatus {
              | Account_not_found =>
                <div className="flex flex-col gap-4">
                  // <UIUtils.RenderIf condition={!HSwitchGlobalVars.isLiveHyperSwitchDashboard}>
                  <ConnectorAccountDetailsHelper.BusinessProfileRender
                    isUpdateFlow selectedConnector={connector}
                  />
                  // </UIUtils.RenderIf>
                  <LandingScreen configuartionType setConfigurationType />
                </div>
              | Redirecting_to_paypal =>
                <RedirectionToPayPalFlow actionUrl setActionUrl connectorId getStatus />
              | Manual_setup_flow =>
                <ManualSetupScreen
                  connector
                  connectorAccountFields
                  selectedConnector
                  connectorMetaDataFields
                  connectorWebHookDetails
                  isUpdateFlow
                  configuartionType
                  connectorLabelDetailField
                />
              | Payments_not_receivable
              | Ppcp_custom_denied
              | More_permissions_needed
              | Email_not_verified =>
                <ErrorPage setupAccountStatus actionUrl getStatus />
              | _ => React.null
              }}
            </div>
            <FormValuesSpy />
          </ConnectorAccountDetailsHelper.ConnectorHeaderWrapper>
          <ConnectorAccountDetailsHelper.VerifyConnectoModal
            showVerifyModal
            setShowVerifyModal
            connector
            verifyErrorMessage
            suggestedActionExists
            suggestedAction
            setVerifyDone
          />
        </div>
      </Form>
      <div className="bg-jp-gray-light_gray_bg flex py-4 px-10 gap-2">
        <img src="/assets/PayPalFullLogo.svg" />
        <p className=p2RedularTextClass>
          {"| Hyperswitch is PayPal's trusted partner, your credentials are secure & never stored with us."->React.string}
        </p>
      </div>
    </PageLoaderWrapper>
  </div>
}