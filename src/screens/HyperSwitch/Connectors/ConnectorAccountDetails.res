@react.component
let make = (
  ~currentStep,
  ~setCurrentStep,
  ~setInitialValues,
  ~initialValues,
  ~isUpdateFlow,
  ~isPayoutFlow,
) => {
  open ConnectorUtils
  open APIUtils
  open ConnectorAccountDetailsHelper
  let hyperswitchMixPanel = HSMixPanel.useSendEvent()
  let url = RescriptReactRouter.useUrl()
  let showToast = ToastState.useShowToast()
  let connector = UrlUtils.useGetFilterDictFromUrl("")->LogicUtils.getString("name", "")
  let connectorID = url.path->Belt.List.toArray->Belt.Array.get(1)->Belt.Option.getWithDefault("")
  let (screenState, setScreenState) = React.useState(_ => PageLoaderWrapper.Loading)
  let featureFlagDetails = HyperswitchAtom.featureFlagAtom->Recoil.useRecoilValueFromAtom

  let updateDetails = useUpdateMethod(~showErrorToast=false, ())

  let (verifyDone, setVerifyDone) = React.useState(_ => ConnectorTypes.NoAttempt)
  let (showVerifyModal, setShowVerifyModal) = React.useState(_ => false)
  let (verifyErrorMessage, setVerifyErrorMessage) = React.useState(_ => None)

  let selectedConnector = React.useMemo1(() => {
    connector->getConnectorNameTypeFromString->getConnectorInfo
  }, [connector])

  let defaultBusinessProfile = Recoil.useRecoilValueFromAtom(HyperswitchAtom.businessProfilesAtom)

  let activeBusinessProfile =
    defaultBusinessProfile->MerchantAccountUtils.getValueFromBusinessProfile

  React.useEffect1(() => {
    mixpanelEventWrapper(
      ~url,
      ~selectedConnector=connector,
      ~actionName=`${isUpdateFlow ? "settings_entry_updateflow" : "settings_entry"}`,
      ~hyperswitchMixPanel,
    )
    None
  }, [connector])

  React.useEffect1(() => {
    if !isUpdateFlow {
      let defaultJsonOnNewConnector =
        [("profile_id", activeBusinessProfile.profile_id->Js.Json.string)]
        ->Js.Dict.fromArray
        ->Js.Json.object_
      setInitialValues(_ => defaultJsonOnNewConnector)
    }
    None
  }, [activeBusinessProfile.profile_id])

  let connectorDetails = React.useMemo1(() => {
    try {
      if connector->Js.String2.length > 0 {
        let dict = isPayoutFlow
          ? Window.getPayoutConnectorConfig(connector)
          : Window.getConnectorConfig(connector)
        setScreenState(_ => Success)
        dict
      } else {
        Js.Dict.empty()->Js.Json.object_
      }
    } catch {
    | Js.Exn.Error(e) => {
        Js.log2("FAILED TO LOAD CONNECTOR CONFIG", e)
        let err = Js.Exn.message(e)->Belt.Option.getWithDefault("Something went wrong")
        setScreenState(_ => PageLoaderWrapper.Error(err))
        Js.Dict.empty()->Js.Json.object_
      }
    }
  }, [connector])

  let (
    bodyType,
    connectorAccountFields,
    connectorMetaDataFields,
    isVerifyConnector,
    connectorWebHookDetails,
    connectorLabelDetailField,
  ) = getConnectorFields(connectorDetails)

  let (showModal, setShowModal) = React.useState(_ => false)

  let updatedInitialVal = React.useMemo1(() => {
    let initialValuesToDict = initialValues->LogicUtils.getDictFromJsonObject
    if !isUpdateFlow {
      initialValuesToDict->Js.Dict.set(
        "connector_label",
        `${connector}_${activeBusinessProfile.profile_name}`->Js.Json.string,
      )
    }
    if (
      connector
      ->getConnectorNameTypeFromString
      ->checkIsDummyConnector(featureFlagDetails.testProcessors) && !isUpdateFlow
    ) {
      let apiKeyDict = [("api_key", "test_key"->Js.Json.string)]->Js.Dict.fromArray
      initialValuesToDict->Js.Dict.set("connector_account_details", apiKeyDict->Js.Json.object_)

      initialValuesToDict->Js.Json.object_
    } else {
      initialValues
    }
  }, [connector])

  let onSubmitMain = async values => {
    open ConnectorTypes
    try {
      let body = generateInitialValuesDict(
        ~values,
        ~connector,
        ~bodyType,
        ~isPayoutFlow,
        ~isLiveMode={featureFlagDetails.isLiveMode},
        (),
      )
      setScreenState(_ => Loading)
      getMixpanelForConnectorOnSubmit(
        ~connectorName=connector,
        ~currentStep,
        ~isUpdateFlow,
        ~url,
        ~hyperswitchMixPanel,
      )
      setCurrentStep(_ => PaymentMethods)
      setScreenState(_ => Success)
      setInitialValues(_ => body)
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
              setCurrentStep(_ => IntegFields)
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
      }
    }
  }

  let onSubmitVerify = async values => {
    try {
      let body =
        generateInitialValuesDict(
          ~values,
          ~connector,
          ~bodyType,
          ~isPayoutFlow,
          ~isLiveMode={featureFlagDetails.isLiveMode},
          (),
        )->ignoreFields(connectorID, verifyConnectorIgnoreField)

      let url = APIUtils.getURL(
        ~entityName=CONNECTOR,
        ~methodType=Post,
        ~connector=Some(connector),
        (),
      )
      let _ = await updateDetails(url, body, Post)
      setShowVerifyModal(_ => false)
      onSubmitMain(values)->ignore
    } catch {
    | Js.Exn.Error(e) =>
      switch Js.Exn.message(e) {
      | Some(message) => {
          let errorMessage = message->parseIntoMyData
          setVerifyErrorMessage(_ => errorMessage.message)
          setShowVerifyModal(_ => true)
          setVerifyDone(_ => Failure)
          hyperswitchMixPanel(
            ~isApiFailure=true,
            ~apiUrl=`/verify_connector`,
            ~description=errorMessage->Js.Json.stringifyAny,
            (),
          )
        }

      | None => setScreenState(_ => Error("Failed to Fetch!"))
      }
    }
  }

  let validateMandatoryField = values => {
    let errors = Js.Dict.empty()
    let valuesFlattenJson = values->JsonFlattenUtils.flattenObject(true)
    let profileId = valuesFlattenJson->LogicUtils.getString("profile_id", "")
    if profileId->Js.String2.length === 0 {
      Js.Dict.set(errors, "Profile Id", `Please select your business profile`->Js.Json.string)
    }

    validateConnectorRequiredFields(
      bodyType,
      connector->getConnectorNameTypeFromString,
      valuesFlattenJson,
      connectorAccountFields,
      connectorMetaDataFields,
      connectorWebHookDetails,
      connectorLabelDetailField,
      errors->Js.Json.object_,
    )
  }

  let buttonText = switch verifyDone {
  | NoAttempt =>
    if !isUpdateFlow {
      "Connect and Proceed"
    } else {
      "Proceed"
    }
  | Failure => "Try Again"
  | _ => "Loading..."
  }

  let (suggestedAction, suggestedActionExists) = ConnectorUtils.getSuggestedAction(
    ~verifyErrorMessage,
    ~connector,
  )
  let handleConnectorConnected = values => {
    ConnectorUtils.onSubmit(
      ~values,
      ~onSubmitVerify,
      ~onSubmitMain,
      ~setVerifyDone,
      ~verifyDone,
      ~isVerifyConnector,
      ~hyperswitchMixPanel,
      ~path={url.path},
      ~isVerifyConnectorFeatureEnabled=featureFlagDetails.verifyConnector,
    )->ignore
  }
  let handleStateToNextPage = () => {
    setCurrentStep(_ => PaymentMethods)
  }

  <PageLoaderWrapper screenState>
    {switch connector->getConnectorNameTypeFromString {
    | PAYPAL =>
      <ConnectPayPal
        connector
        connectorAccountFields
        selectedConnector
        connectorMetaDataFields
        connectorWebHookDetails
        isUpdateFlow
        setInitialValues
        handleConnectorConnected
        initialValues
        setShowModal
        showVerifyModal
        setShowVerifyModal
        verifyErrorMessage
        setVerifyDone
        handleStateToNextPage
        connectorLabelDetailField
      />
    | _ =>
      <Form
        initialValues={updatedInitialVal}
        onSubmit={(values, _) =>
          ConnectorUtils.onSubmit(
            ~values,
            ~onSubmitVerify,
            ~onSubmitMain,
            ~setVerifyDone,
            ~verifyDone,
            ~isVerifyConnector,
            ~hyperswitchMixPanel,
            ~path={url.path},
            ~isVerifyConnectorFeatureEnabled=featureFlagDetails.verifyConnector,
          )}
        validate={validateMandatoryField}
        formClass="flex flex-col ">
        <ConnectorHeaderWrapper
          connector
          headerButton={<FormRenderer.SubmitButton loadingText="Processing..." text=buttonText />}
          setShowModal>
          <UIUtils.RenderIf condition={featureFlagDetails.businessProfile}>
            <div className="flex flex-col gap-2 p-2 md:p-10">
              <ConnectorAccountDetailsHelper.BusinessProfileRender
                isUpdateFlow selectedConnector={connector}
              />
            </div>
          </UIUtils.RenderIf>
          <div className="flex flex-col gap-2 p-2 md:p-10">
            <div className="grid grid-cols-2 flex-1">
              <ConnectorConfigurationFields
                connector={connector->getConnectorNameTypeFromString}
                connectorAccountFields
                selectedConnector
                connectorMetaDataFields
                connectorWebHookDetails
                bodyType
                connectorLabelDetailField
              />
            </div>
            <IntegrationHelp.Render connector setShowModal showModal />
          </div>
          <FormValuesSpy />
        </ConnectorHeaderWrapper>
        <VerifyConnectoModal
          showVerifyModal
          setShowVerifyModal
          connector
          verifyErrorMessage
          suggestedActionExists
          suggestedAction
          setVerifyDone
        />
      </Form>
    }}
  </PageLoaderWrapper>
}
