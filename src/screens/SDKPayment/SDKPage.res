let h3Leading2Style = HSwitchUtils.getTextClass((H3, Leading_2))

module SDKConfiguarationFields = {
  open MerchantAccountUtils
  @react.component
  let make = (~initialValues: SDKPaymentTypes.paymentType) => {
    let businessProfiles = Recoil.useRecoilValueFromAtom(HyperswitchAtom.businessProfilesAtom)
    let disableSelectionForProfile = businessProfiles->HomeUtils.isDefaultBusinessProfile
    let connectorList = HyperswitchAtom.connectorListAtom->Recoil.useRecoilValueFromAtom
    let dropDownOptions = HomeUtils.countries->Array.map((item): SelectBox.dropdownOption => {
      {
        label: `${item.countryName} (${item.currency})`,
        value: `${item.isoAlpha2}-${item.currency}`,
      }
    })

    let selectProfileField = FormRenderer.makeFieldInfo(
      ~label="Profile",
      ~name="profile_id",
      ~placeholder="",
      ~customInput=InputFields.selectInput(
        ~deselectDisable=true,
        ~options={businessProfiles->businessProfileNameDropDownOption},
        ~buttonText="Select Profile",
        ~disableSelect=disableSelectionForProfile,
        ~fullLength=true,
        (),
      ),
      (),
    )
    let selectCurrencyField = FormRenderer.makeFieldInfo(
      ~label="Currency",
      ~name="country_currency",
      ~placeholder="",
      ~customInput=InputFields.selectInput(
        ~options=dropDownOptions,
        ~buttonText="Select Currency",
        ~deselectDisable=true,
        ~fullLength=true,
        (),
      ),
      (),
    )
    let enterAmountField = FormRenderer.makeFieldInfo(
      ~label="Enter amount",
      ~name="amount",
      ~customInput=(~input, ~placeholder as _) =>
        InputFields.numericTextInput(~isDisabled=false, ~customStyle="w-full", ~precision=2, ())(
          ~input={
            ...input,
            value: (initialValues.amount /. 100.00)->Float.toString->JSON.Encode.string,
            onChange: {
              ev => {
                let eventValueToFloat =
                  ev->Identity.formReactEventToString->LogicUtils.getFloatFromString(0.00)
                let valInCents =
                  (eventValueToFloat *. 100.00)->Float.toString->Identity.stringToFormReactEvent
                input.onChange(valInCents)
              }
            },
          },
          ~placeholder="Enter amount",
        ),
      (),
    )

    <div className="w-full">
      <FormRenderer.FieldRenderer field=selectProfileField fieldWrapperClass="!w-full" />
      <FormRenderer.FieldRenderer field=selectCurrencyField fieldWrapperClass="!w-full" />
      <FormRenderer.FieldRenderer field=enterAmountField fieldWrapperClass="!w-full" />
      <FormRenderer.SubmitButton
        text="Show preview"
        disabledParamter={initialValues.profile_id->LogicUtils.isEmptyString ||
          connectorList->Array.length <= 0}
        customSumbitButtonStyle="!mt-5"
      />
    </div>
  }
}

@react.component
let make = () => {
  open MerchantAccountUtils
  let url = RescriptReactRouter.useUrl()
  let filtersFromUrl = url.search->LogicUtils.getDictFromUrlSearchParams
  let (isSDKOpen, setIsSDKOpen) = React.useState(_ => false)
  let (key, setKey) = React.useState(_ => "")
  let businessProfiles = Recoil.useRecoilValueFromAtom(HyperswitchAtom.businessProfilesAtom)
  let defaultBusinessProfile = businessProfiles->getValueFromBusinessProfile
  let (initialValues, setInitialValues) = React.useState(_ =>
    defaultBusinessProfile->SDKPaymentUtils.initialValueForForm
  )
  let connectorList = HyperswitchAtom.connectorListAtom->Recoil.useRecoilValueFromAtom
  React.useEffect(() => {
    let paymentIntentOptional = filtersFromUrl->Dict.get("payment_intent_client_secret")
    if paymentIntentOptional->Option.isSome {
      setIsSDKOpen(_ => true)
    }
    None
  }, [filtersFromUrl])

  React.useEffect(() => {
    setInitialValues(_ => defaultBusinessProfile->SDKPaymentUtils.initialValueForForm)
    None
  }, [defaultBusinessProfile.profile_id->String.length])

  let onProceed = async (~paymentId) => {
    switch paymentId {
    | Some(val) =>
      RescriptReactRouter.replace(GlobalVars.appendDashboardPath(~url=`/payments/${val}`))
    | None => ()
    }
  }

  let onSubmit = (values, _) => {
    setKey(_ => Date.now()->Float.toString)
    setInitialValues(_ => values->SDKPaymentUtils.getTypedValueForPayment)
    setIsSDKOpen(_ => true)
    RescriptReactRouter.push(GlobalVars.appendDashboardPath(~url="/sdk"))
    Nullable.null->Promise.resolve
  }

  <>
    <BreadCrumbNavigation
      path=[{title: "Home", link: `/home`}] currentPageTitle="Explore Demo Checkout Experience"
    />
    <div className="w-full flex border rounded-md bg-white">
      <div className="flex flex-col w-1/2 border">
        <div className="p-6 border-b-1 border-[#E6E6E6]">
          <p className=h3Leading2Style> {"Setup test checkout"->React.string} </p>
        </div>
        <div className="p-7 flex flex-col gap-16">
          <Form
            initialValues={initialValues->Identity.genericTypeToJson}
            formClass="grid grid-cols-2 gap-x-8 gap-y-4"
            onSubmit>
            <SDKConfiguarationFields initialValues />
          </Form>
          <TestCredentials />
        </div>
      </div>
      <div className="flex flex-col flex-1">
        <div className="p-6 border-l-1 border-b-1 border-[#E6E6E6]">
          <p className=h3Leading2Style> {"Preview"->React.string} </p>
        </div>
        {if isSDKOpen {
          <div className="p-7 h-full bg-sidebar-blue">
            <TestPayment
              key
              returnUrl={`${GlobalVars.getHostUrlWithBasePath}/sdk`}
              onProceed
              sdkWidth="!w-[100%]"
              isTestCredsNeeded=false
              customWidth="!w-full !h-full"
              paymentStatusStyles=""
              successButtonText="Go to Payment"
              keyValue={key}
              initialValues
            />
          </div>
        } else if connectorList->Array.length <= 0 {
          <HelperComponents.BluredTableComponent
            infoText={"Connect to a payment processor to make your first payment"}
            buttonText={"Connect a connector"}
            moduleName=""
            onClickUrl={`/connectors`}
          />
        } else {
          <div className="bg-sidebar-blue flex items-center justify-center h-full">
            <img alt="blurry-sdk" src={`/assets/BlurrySDK.svg`} />
          </div>
        }}
      </div>
    </div>
  </>
}
