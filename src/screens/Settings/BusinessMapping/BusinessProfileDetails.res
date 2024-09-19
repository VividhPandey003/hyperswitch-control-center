module InfoViewForWebhooks = {
  @react.component
  let make = (~heading, ~subHeading, ~isCopy=false, ~customRightComp=?) => {
    let showToast = ToastState.useShowToast()
    let onCopyClick = ev => {
      ev->ReactEvent.Mouse.stopPropagation
      Clipboard.writeText(subHeading)
      showToast(~message="Copied to Clipboard!", ~toastType=ToastSuccess)
    }

    <div className="flex flex-col gap-2 m-2 md:m-4 w-1/2">
      <p className="font-semibold text-fs-15"> {heading->React.string} </p>
      <div className="flex gap-2 break-all w-full items-start">
        <p className="font-medium text-fs-14 text-black opacity-50"> {subHeading->React.string} </p>
        <RenderIf condition={isCopy}>
          <img
            alt="copy-clipboard"
            src={`/assets/CopyToClipboard.svg`}
            className="cursor-pointer"
            onClick={ev => {
              onCopyClick(ev)
            }}
          />
        </RenderIf>
        {customRightComp->Option.getOr(React.null)}
      </div>
    </div>
  }
}

module AuthenticationInput = {
  @react.component
  let make = (~index) => {
    open LogicUtils
    open FormRenderer
    let formState: ReactFinalForm.formState = ReactFinalForm.useFormState(
      ReactFinalForm.useFormSubscription(["values"])->Nullable.make,
    )
    let (key, setKey) = React.useState(_ => "")
    let (metaValue, setValue) = React.useState(_ => "")
    let getOutGoingWebhook = () => {
      let outGoingWebhookDict =
        formState.values
        ->getDictFromJsonObject
        ->getDictfromDict("outgoing_webhook_custom_http_headers")
      let key = outGoingWebhookDict->Dict.keysToArray->getValueFromArray(index, "")
      let outGoingWebHookVal = outGoingWebhookDict->getOptionString(key)
      switch outGoingWebHookVal {
      | Some(value) => (key, value)
      | _ => ("", "")
      }
    }
    React.useEffect(() => {
      let (outGoingWebhookKey, outGoingWebHookValue) = getOutGoingWebhook()
      setValue(_ => outGoingWebHookValue)
      setKey(_ => outGoingWebhookKey)

      None
    }, [])
    let form = ReactFinalForm.useForm()
    let keyInput: ReactFinalForm.fieldRenderPropsInput = {
      name: "string",
      onBlur: _ => (),
      onChange: ev => {
        let value = ReactEvent.Form.target(ev)["value"]
        if value->String.length <= 0 {
          let name = `outgoing_webhook_custom_http_headers.${key}`
          form.change(name, JSON.Encode.null)
        }
        if value->getOptionIntFromString->Option.isNone {
          setKey(_ => value)
        }
      },
      onFocus: _ => (),
      value: key->JSON.Encode.string,
      checked: true,
    }
    let valueInput: ReactFinalForm.fieldRenderPropsInput = {
      name: "string",
      onBlur: _ => {
        if key->isNonEmptyString {
          let name = `outgoing_webhook_custom_http_headers.${key}`
          form.change(name, metaValue->JSON.Encode.string)
        }
      },
      onChange: ev => {
        let value = ReactEvent.Form.target(ev)["value"]
        setValue(_ => value)
      },
      onFocus: _ => (),
      value: metaValue->JSON.Encode.string,
      checked: true,
    }

    <DesktopRow wrapperClass="flex-1">
      <div className="mt-5">
        <TextInput input={keyInput} placeholder={"Enter key"} />
      </div>
      <div className="mt-5">
        <TextInput input={valueInput} placeholder={"Enter value"} />
      </div>
    </DesktopRow>
  }
}
module WebHookAuthenticationHeaders = {
  @react.component
  let make = () => {
    <div className="flex-1">
      <p
        className="text-fs-13 dark:text-jp-gray-text_darktheme dark:text-opacity-50 !text-base !text-grey-700 font-semibold ml-1">
        {"Custom HTTP Headers"->React.string}
      </p>
      <div className="grid grid-cols-5 gap-2">
        {Array.fromInitializer(~length=4, i => i)
        ->Array.mapWithIndex((_, index) =>
          <div key={index->Int.toString} className="col-span-4">
            <AuthenticationInput index={index} />
          </div>
        )
        ->React.array}
      </div>
    </div>
  }
}

module WebHook = {
  @react.component
  let make = (~setCustomHttpHeaders, ~enableCustomHttpHeaders) => {
    open FormRenderer
    open LogicUtils
    let {customWebhookHeaders} = HyperswitchAtom.featureFlagAtom->Recoil.useRecoilValueFromAtom
    let form = ReactFinalForm.useForm()
    let formState: ReactFinalForm.formState = ReactFinalForm.useFormState(
      ReactFinalForm.useFormSubscription(["values"])->Nullable.make,
    )
    let h2RegularTextStyle = `${HSwitchUtils.getTextClass((H3, Leading_1))}`
    let webHookURL =
      formState.values
      ->getDictFromJsonObject
      ->getOptionString("webhook_url")
      ->Option.isSome
    let outGoingHeaders =
      formState.values
      ->getDictFromJsonObject
      ->getDictfromDict("outgoing_webhook_custom_http_headers")
      ->isEmptyDict

    React.useEffect(() => {
      if !webHookURL {
        setCustomHttpHeaders(_ => false)
        form.change("outgoing_webhook_custom_http_headers", JSON.Encode.null)
      }
      None
    }, [webHookURL])

    let updateCustomHttpHeaders = () => {
      setCustomHttpHeaders(_ => !enableCustomHttpHeaders)
    }
    React.useEffect(() => {
      if webHookURL && !outGoingHeaders {
        setCustomHttpHeaders(_ => true)
      }
      None
    }, [])
    <>
      <div>
        <div className="ml-4">
          <p className=h2RegularTextStyle> {"Webhook Setup"->React.string} </p>
        </div>
        <div className="ml-4 mt-4">
          <FieldRenderer
            field={DeveloperUtils.webhookUrl}
            labelClass="!text-base !text-grey-700 font-semibold"
            fieldWrapperClass="max-w-xl"
          />
        </div>
        <RenderIf condition={customWebhookHeaders}>
          <div className="ml-4">
            <div className="mt-4 flex items-center text-jp-gray-700 font-bold self-start">
              <div className="font-semibold text-base text-black dark:text-white">
                {"Enable Custom HTTP Headers"->React.string}
              </div>
              <ToolTip description="Enter Webhook url to enable" toolTipPosition=ToolTip.Right />
            </div>
            <div className="mt-4">
              <BoolInput.BaseComponent
                boolCustomClass="rounded-lg"
                isSelected=enableCustomHttpHeaders
                size={Large}
                setIsSelected={_ => webHookURL ? updateCustomHttpHeaders() : ()}
              />
            </div>
          </div>
        </RenderIf>
      </div>
      <RenderIf condition={enableCustomHttpHeaders && customWebhookHeaders}>
        <WebHookAuthenticationHeaders />
      </RenderIf>
    </>
  }
}

module ReturnUrl = {
  @react.component
  let make = () => {
    open FormRenderer
    <DesktopRow>
      <FieldRenderer
        field={DeveloperUtils.returnUrl}
        errorClass={HSwitchUtils.errorClass}
        labelClass="!text-base !text-grey-700 font-semibold"
        fieldWrapperClass="max-w-xl"
      />
    </DesktopRow>
  }
}

type options = {
  name: string,
  key: string,
}

module CollectDetails = {
  @react.component
  let make = (~title, ~options: array<options>) => {
    open LogicUtils
    let formState: ReactFinalForm.formState = ReactFinalForm.useFormState(
      ReactFinalForm.useFormSubscription(["values"])->Nullable.make,
    )
    let valuesDict = formState.values->getDictFromJsonObject
    let initValue = options->Array.some(option => valuesDict->getBool(option.key, false))
    let (isSelected, setIsSelected) = React.useState(_ => initValue)
    let form = ReactFinalForm.useForm()

    let onClick = key => {
      options->Array.forEach(option => {
        form.change(option.key, (option.key === key)->JSON.Encode.bool)
      })
    }

    let p2RegularTextStyle = `${HSwitchUtils.getTextClass((P1, Medium))} text-grey-700 opacity-50`

    React.useEffect(() => {
      if isSelected {
        let value = options->Array.some(option => valuesDict->getBool(option.key, false))
        if !value {
          switch options->Array.get(0) {
          | Some(name) => form.change(name.key, true->JSON.Encode.bool)
          | _ => ()
          }
        }
      } else {
        options->Array.forEach(option => form.change(option.key, false->JSON.Encode.bool))
      }
      None
    }, [isSelected])

    <div>
      <div className="flex gap-2 items-center">
        <BoolInput.BaseComponent
          isSelected
          setIsSelected={_ => setIsSelected(val => !val)}
          isDisabled=false
          boolCustomClass="rounded-lg"
        />
        <p className="!text-base !text-grey-700 font-semibold"> {title->React.string} </p>
      </div>
      <RenderIf condition={isSelected}>
        <div className="mt-4">
          {options
          ->Array.mapWithIndex((option, index) =>
            <div
              key={index->Int.toString}
              className="flex gap-2 mb-3 items-center cursor-pointer"
              onClick={_ => onClick(option.key)}>
              <RadioIcon
                isSelected={valuesDict->getBool(option.key, false)} fill="text-green-700"
              />
              <div className=p2RegularTextStyle>
                {option.name->LogicUtils.snakeToTitle->React.string}
              </div>
            </div>
          )
          ->React.array}
        </div>
      </RenderIf>
    </div>
  }
}

module EditProfileName = {
  @react.component
  let make = (~defaultProfileName, ~profileId) => {
    open APIUtils
    let getURL = useGetURL()
    let updateDetails = useUpdateMethod()
    let showToast = ToastState.useShowToast()
    let (showModal, setShowModal) = React.useState(_ => false)
    let (businessProfiles, setBusinessProfiles) = Recoil.useRecoilState(
      HyperswitchAtom.businessProfilesAtom,
    )

    let initialValues = [("profile_name", defaultProfileName->JSON.Encode.string)]->Dict.fromArray

    let onSubmit = async (values, _) => {
      try {
        let url = getURL(~entityName=BUSINESS_PROFILE, ~methodType=Post, ~id=Some(profileId))
        let res = await updateDetails(url, values, Post)
        let filteredProfileList =
          businessProfiles
          ->Array.filter(businessProfile => businessProfile.profile_id !== profileId)
          ->Array.concat([res->BusinessProfileMapper.businessProfileTypeMapper])

        setBusinessProfiles(_ => filteredProfileList)
        showToast(~message="Updated profile name!", ~toastType=ToastSuccess)
      } catch {
      | _ => showToast(~message="Failed to update profile name!", ~toastType=ToastError)
      }
      setShowModal(_ => false)
      Nullable.null
    }

    let businessName = FormRenderer.makeFieldInfo(
      ~label="Profile Name",
      ~name="profile_name",
      ~placeholder=`Eg: Hyperswitch`,
      ~customInput=InputFields.textInput(),
      ~isRequired=true,
    )

    <div className="flex gap-4 items-center">
      <ToolTip
        description="Edit profile name"
        toolTipFor={<Icon
          name="pencil-alt"
          size=14
          className="cursor-pointer"
          onClick={ev => {
            ev->ReactEvent.Mouse.stopPropagation
            setShowModal(_ => true)
          }}
        />}
        toolTipPosition=ToolTip.Top
        contentAlign={Left}
      />
      <Modal
        key=defaultProfileName
        modalHeading="Edit Profile name"
        showModal
        setShowModal
        modalClass="w-1/4 m-auto">
        <Form initialValues={initialValues->JSON.Encode.object} onSubmit>
          <div className="flex flex-col gap-12 h-full w-full">
            <FormRenderer.DesktopRow>
              <FormRenderer.FieldRenderer
                fieldWrapperClass="w-full"
                field={businessName}
                labelClass="!text-black font-medium !-ml-[0.5px]"
              />
            </FormRenderer.DesktopRow>
            <div className="flex justify-end w-full pr-5 pb-3">
              <FormRenderer.SubmitButton text="Submit changes" buttonSize={Small} />
            </div>
          </div>
        </Form>
      </Modal>
    </div>
  }
}

@react.component
let make = (~webhookOnly=false, ~showFormOnly=false, ~profileId="") => {
  open DeveloperUtils
  open APIUtils
  open HSwitchUtils
  open MerchantAccountUtils
  open HSwitchSettingTypes
  open FormRenderer
  let getURL = useGetURL()
  let url = RescriptReactRouter.useUrl()
  let id = HSwitchUtils.getConnectorIDFromUrl(url.path->List.toArray, profileId)
  let businessProfileDetails = BusinessProfileHook.useGetBusinessProflile(id)
  let featureFlagDetails = HyperswitchAtom.featureFlagAtom->Recoil.useRecoilValueFromAtom
  let showToast = ToastState.useShowToast()
  let updateDetails = useUpdateMethod()

  let (busiProfieDetails, setBusiProfie) = React.useState(_ => businessProfileDetails)

  let (screenState, setScreenState) = React.useState(_ => PageLoaderWrapper.Success)
  let (enableCustomHttpHeaders, setCustomHttpHeaders) = React.useState(_ => false)
  let bgClass = webhookOnly ? "" : "bg-white dark:bg-jp-gray-lightgray_background"
  let fetchBusinessProfiles = BusinessProfileHook.useFetchBusinessProfiles()

  let threedsConnectorList =
    HyperswitchAtom.connectorListAtom
    ->Recoil.useRecoilValueFromAtom
    ->Array.filter(item =>
      item.connector_type->ConnectorUtils.connectorTypeStringToTypeMapper ===
        AuthenticationProcessor
    )

  let isBusinessProfileHasThreeds = threedsConnectorList->Array.some(item => item.profile_id == id)

  let fieldsToValidate = () => {
    let defaultFieldsToValidate =
      [WebhookUrl, ReturnUrl]->Array.filter(urlField => urlField === WebhookUrl || !webhookOnly)
    defaultFieldsToValidate
  }

  React.useEffect(() => {
    setBusiProfie(_ => businessProfileDetails)
    None
  }, [businessProfileDetails])

  let onSubmit = async (values, _) => {
    try {
      open LogicUtils
      setScreenState(_ => PageLoaderWrapper.Loading)
      let valuesDict = values->getDictFromJsonObject
      if !enableCustomHttpHeaders {
        valuesDict->Dict.set("outgoing_webhook_custom_http_headers", JSON.Encode.null)
      }
      let url = getURL(~entityName=BUSINESS_PROFILE, ~methodType=Post, ~id=Some(id))
      let body = valuesDict->JSON.Encode.object->getBusinessProfilePayload->JSON.Encode.object
      let res = await updateDetails(url, body, Post)
      setBusiProfie(_ => res->BusinessProfileMapper.businessProfileTypeMapper)
      showToast(~message=`Details updated`, ~toastType=ToastState.ToastSuccess)
      setScreenState(_ => PageLoaderWrapper.Success)
      fetchBusinessProfiles()->ignore
    } catch {
    | _ => {
        setScreenState(_ => PageLoaderWrapper.Success)
        showToast(~message=`Failed to updated`, ~toastType=ToastState.ToastError)
      }
    }
    Nullable.null
  }

  <PageLoaderWrapper screenState>
    <div className={`${showFormOnly ? "" : "py-4 md:py-10"} h-full flex flex-col`}>
      <RenderIf condition={!showFormOnly}>
        <BreadCrumbNavigation
          path=[
            {
              title: "Business Profiles",
              link: "/business-profiles",
            },
          ]
          currentPageTitle={busiProfieDetails.profile_name}
          cursorStyle="cursor-pointer"
        />
      </RenderIf>
      <div className={`${showFormOnly ? "" : "mt-4"}`}>
        <div
          className={`w-full ${showFormOnly
              ? ""
              : "border border-jp-gray-500 rounded-md dark:border-jp-gray-960"} ${bgClass} `}>
          <ReactFinalForm.Form
            key="merchantAccount"
            initialValues={busiProfieDetails->parseBussinessProfileJson->JSON.Encode.object}
            subscription=ReactFinalForm.subscribeToValues
            validate={values => {
              MerchantAccountUtils.validateMerchantAccountForm(
                ~values,
                ~fieldsToValidate={fieldsToValidate()},
                ~isLiveMode=featureFlagDetails.isLiveMode,
              )
            }}
            onSubmit
            render={({handleSubmit}) => {
              <form
                onSubmit={handleSubmit}
                className={`${showFormOnly
                    ? ""
                    : "px-2 py-4"} flex flex-col gap-7 overflow-hidden`}>
                <div className="flex items-center">
                  <InfoViewForWebhooks
                    heading="Profile ID" subHeading=busiProfieDetails.profile_id isCopy=true
                  />
                  <InfoViewForWebhooks
                    heading="Profile Name"
                    subHeading=busiProfieDetails.profile_name
                    customRightComp={<EditProfileName
                      defaultProfileName=busiProfieDetails.profile_name
                      profileId=busiProfieDetails.profile_id
                    />}
                  />
                </div>
                <div className="flex items-center">
                  <InfoViewForWebhooks
                    heading="Merchant ID" subHeading={busiProfieDetails.merchant_id}
                  />
                  <InfoViewForWebhooks
                    heading="Payment Response Hash Key"
                    subHeading={busiProfieDetails.payment_response_hash_key->Option.getOr("NA")}
                    isCopy=true
                  />
                </div>
                <DesktopRow>
                  <CollectDetails
                    title={"Collect billing details from wallets"}
                    options=[
                      {
                        name: "only if required by connector",
                        key: "collect_billing_details_from_wallet_connector",
                      },
                      {
                        name: "always",
                        key: "always_collect_billing_details_from_wallet_connector",
                      },
                    ]
                  />
                  <CollectDetails
                    title={"Collect shipping details from wallets"}
                    options=[
                      {
                        name: "only if required by connector",
                        key: "collect_shipping_details_from_wallet_connector",
                      },
                      {
                        name: "always",
                        key: "always_collect_shipping_details_from_wallet_connector",
                      },
                    ]
                  />
                </DesktopRow>
                <DesktopRow>
                  <FieldRenderer
                    labelClass="!text-base !text-grey-700 font-semibold"
                    fieldWrapperClass="max-w-xl"
                    field={makeFieldInfo(
                      ~name="is_connector_agnostic_mit_enabled",
                      ~label="Connector Agnostic",
                      ~customInput=InputFields.boolInput(
                        ~isDisabled=false,
                        ~boolCustomClass="rounded-lg",
                      ),
                    )}
                  />
                </DesktopRow>
                <RenderIf condition={isBusinessProfileHasThreeds}>
                  <DesktopRow>
                    <FieldRenderer
                      field={threedsConnectorList
                      ->Array.map(item => item.connector_name)
                      ->authenticationConnectors}
                      errorClass
                      labelClass="!text-base !text-grey-700 font-semibold"
                      fieldWrapperClass="max-w-xl"
                    />
                    <FieldRenderer
                      field={threeDsRequestorUrl}
                      errorClass
                      labelClass="!text-base !text-grey-700 font-semibold"
                      fieldWrapperClass="max-w-xl"
                    />
                  </DesktopRow>
                </RenderIf>
                <ReturnUrl />
                <WebHook enableCustomHttpHeaders setCustomHttpHeaders />
                <DesktopRow>
                  <div className="flex justify-start w-full">
                    <SubmitButton
                      customSumbitButtonStyle="justify-start"
                      text="Update"
                      buttonType=Button.Primary
                      buttonSize=Button.Small
                    />
                  </div>
                </DesktopRow>
                <FormValuesSpy />
              </form>
            }}
          />
        </div>
      </div>
    </div>
  </PageLoaderWrapper>
}