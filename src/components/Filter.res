let makeFieldInfo = FormRenderer.makeFieldInfo

module ClearForm = {
  @react.component
  let make = () => {
    let form = ReactFinalForm.useForm()
    <div className="ml-2">
      <Button
        text="Clear Form" onClick={e => form.reset(JSON.Encode.object(Dict.make())->Nullable.make)}
      />
    </div>
  }
}

module ModalUI = {
  @react.component
  let make = (
    ~showModal,
    ~setShowModal,
    ~initialValueJson,
    ~fieldsFromOption,
    ~isButtonDisabled,
  ) => {
    let form = ReactFinalForm.useForm()

    let footerUi =
      <div
        className="flex flex-row justify-between p-4 border-t border-jp-gray-500 dark:border-jp-gray-960 items-center">
        <ClearForm />
        <div className="flex flex-row gap-2 place-content-end">
          <Button
            text="Cancel"
            buttonType=SecondaryFilled
            buttonSize=Small
            onClick={_ev => {
              form.reset(initialValueJson->Nullable.make)
              setShowModal(_ => false)
            }}
          />
          <FormRenderer.SubmitButton text="Submit" disabledParamter=isButtonDisabled />
        </div>
      </div>

    <Modal
      modalHeading="Advanced Search"
      showModal
      setShowModal
      borderBottom=true
      childClass="p-2 m-2"
      modalClass="w-full md:w-2/3 mx-auto mt-0"
      onCloseClickCustomFun={_ev => {
        form.reset(initialValueJson->Nullable.make)
        setShowModal(_ => false)
      }}
      modalFooter=footerUi>
      <AddDataAttributes attributes=[("data-filter", "advanceFilters")]>
        <div
          className="overflow-auto"
          style={ReactDOMStyle.make(~maxHeight="calc(100vh - 15rem)", ())}>
          <div className="flex flex-wrap h-fit">
            {switch fieldsFromOption->Array.get(0) {
            | Some(field) =>
              <FormRenderer.FieldRenderer
                field fieldWrapperClass="w-full !min-w-[200px] p-4 -my-4"
              />
            | None => React.null
            }}
          </div>
          <div className="flex flex-wrap h-fit ">
            {switch fieldsFromOption->Array.get(1) {
            | Some(field) =>
              <FormRenderer.FieldRenderer
                field fieldWrapperClass="w-full !min-w-[200px] p-4 -my-4"
              />
            | None => React.null
            }}
            {switch fieldsFromOption->Array.get(3) {
            | Some(field) =>
              <FormRenderer.FieldRenderer
                field fieldWrapperClass="w-full !min-w-[200px] p-4 -my-4"
              />
            | None => React.null
            }}
          </div>
          <div className="flex flex-wrap h-fit mb-10">
            {switch fieldsFromOption->Array.get(2) {
            | Some(field) =>
              <FormRenderer.FieldRenderer
                field fieldWrapperClass="w-full !min-w-[200px] p-4 -my-4"
              />
            | None => React.null
            }}
            <FormRenderer.FieldsRenderer
              fields={fieldsFromOption->Array.sliceToEnd(~start=4)}
              fieldWrapperClass="w-1/3 !min-w-[200px] p-4 -my-4"
            />
          </div>
        </div>
      </AddDataAttributes>
    </Modal>
  }
}

module ClearFilters = {
  @react.component
  let make = (
    ~filterButtonStyle,
    ~defaultFilterKeys=[],
    ~clearFilters=?,
    ~count,
    ~isCountRequired=true,
    ~outsidefilter=false,
  ) => {
    let {updateExistingKeys} = React.useContext(FilterContext.filterContext)
    let isMobileView = MatchMedia.useMobileChecker()
    let outerClass = if isMobileView {
      "flex items-center justify-end"
    } else {
      "mt-1 ml-10"
    }
    let textStyle = ""
    let leftIcon: Button.iconType = CustomIcon(<Icon name="clear_filter_img" size=14 />)

    let formState: ReactFinalForm.formState = ReactFinalForm.useFormState(
      ReactFinalForm.useFormSubscription(["values", "initialValues"])->Nullable.make,
    )

    let handleClearFilter = switch clearFilters {
    | Some(fn) =>
      _ => {
        fn()

        // fn()
      }
    | None =>
      _ => {
        let searchStr =
          formState.values
          ->JSON.Decode.object
          ->Option.getOr(Dict.make())
          ->Dict.toArray
          ->Belt.Array.keepMap(entry => {
            let (key, value) = entry
            switch defaultFilterKeys->Array.includes(key) {
            | true =>
              switch value->JSON.Classify.classify {
              | String(str) => `${key}=${str}`->Some
              | Number(num) => `${key}=${num->String.make}`->Some
              | Array(arr) => `${key}=[${arr->String.make}]`->Some
              | _ => None
              }
            | false => None
            }
          })
          ->Array.joinWith("&")

        searchStr->FilterUtils.parseFilterString->updateExistingKeys
      }
    }

    let hasExtraFilters = React.useMemo2(() => {
      formState.initialValues
      ->JSON.Decode.object
      ->Option.getOr(Dict.make())
      ->Dict.toArray
      ->Array.filter(entry => {
        let (key, value) = entry
        let isEmptyValue = switch value->JSON.Classify.classify {
        | String(str) => str->LogicUtils.isEmptyString
        | Array(arr) => arr->Array.length === 0
        | Null => true
        | _ => false
        }

        !(defaultFilterKeys->Array.includes(key)) && !isEmptyValue
      })
      ->Array.length > 0
    }, (formState.initialValues, defaultFilterKeys))
    let text = isCountRequired ? `Clear ${count->Int.toString} Filters` : "Clear Filters"
    <UIUtils.RenderIf condition={hasExtraFilters || outsidefilter}>
      <div className={`${filterButtonStyle} ${outerClass}`}>
        <Button
          text showBorder=false textStyle leftIcon onClick=handleClearFilter buttonType=NonFilled
        />
      </div>
    </UIUtils.RenderIf>
  }
}

module CheckCustomFilters = {
  @react.component
  let make = (
    ~options: array<EntityType.optionType<'t>>,
    ~checkedFilters,
    ~removeFilters,
    ~addFilters,
    ~showAddFilter,
    ~showSelectFiltersSearch,
  ) => {
    let formState: ReactFinalForm.formState = ReactFinalForm.useFormState(
      ReactFinalForm.useFormSubscription(["values"])->Nullable.make,
    )
    let values = formState.values

    let onChangeSelect = ev => {
      let fieldNameArr = ev->Identity.formReactEventToArrayOfString
      let newlyAdded = Array.filter(fieldNameArr, newVal => !Array.includes(checkedFilters, newVal))

      if Array.length(newlyAdded) > 0 {
        addFilters(newlyAdded)
      } else {
        removeFilters(fieldNameArr, values)
      }
    }

    let selectOptions = options->Array.map(obj => obj.urlKey)

    <div className="md:justify-between flex p-1 items-center flex-wrap">
      {if Array.length(options) > 0 && showAddFilter {
        <div className="flex flex-wrap">
          <CustomInputSelectBox
            onChange=onChangeSelect
            options={selectOptions->Array.map(item => {
              {
                SelectBox.label: LogicUtils.snakeToTitle(item),
                SelectBox.value: item,
              }
            })}
            allowMultiSelect=true
            buttonText="Add Filters"
            isDropDown=true
            hideMultiSelectButtons=true
            buttonType=Button.FilterAdd
            value={checkedFilters->Array.map(JSON.Encode.string)->JSON.Encode.array}
            searchable=showSelectFiltersSearch
          />
        </div>
      } else {
        React.null
      }}
    </div>
  }
}

let defaultAutoApply = false

module AutoSubmitter = {
  @react.component
  let make = (~showModal, ~autoApply, ~submit, ~defaultFilterKeys) => {
    let formState: ReactFinalForm.formState = ReactFinalForm.useFormState(
      ReactFinalForm.useFormSubscription(["values", "dirtyFields"])->Nullable.make,
    )

    let values = formState.values

    React.useEffect1(() => {
      if formState.dirty {
        let defaultFieldsHaveChanged = defaultFilterKeys->Array.some(key => {
          formState.dirtyFields->Dict.get(key)->Option.getOr(false)
        })

        // if autoApply is false then still autoApply can work for the default filters
        if !showModal && (autoApply || defaultFieldsHaveChanged) {
          submit(formState.values, 0)->ignore
        }
      }

      None
    }, [values])

    React.null
  }
}

let getStrFromJson = (key, val) => {
  switch val->JSON.Classify.classify {
  | String(str) => str
  | Array(array) => array->Array.length > 0 ? `[${array->Array.joinWithUnsafe(",")}]` : ""
  | Number(num) => key === "offset" ? "0" : num->Float.toInt->Int.toString
  | _ => ""
  }
}

module ApplyFilterButton = {
  @react.component
  let make = (
    ~autoApply,
    ~totalFilters,
    ~hideFilters,
    ~filterButtonStyle,
    ~defaultFilterKeys,
    ~selectedFiltersList: array<FormRenderer.fieldInfoType>,
  ) => {
    let defaultinputField = FormRenderer.makeInputFieldInfo(~name="-", ())
    let inputFieldsDict =
      selectedFiltersList
      ->Array.map(filter => {
        let inputFieldsArr = filter.inputFields
        let inputField = inputFieldsArr->LogicUtils.getValueFromArray(0, defaultinputField)
        (inputField.name, inputField)
      })
      ->Dict.fromArray

    let formState: ReactFinalForm.formState = ReactFinalForm.useFormState(
      ReactFinalForm.useFormSubscription(["values", "dirtyFields", "initialValues"])->Nullable.make,
    )

    let formCurrentValues =
      formState.values
      ->LogicUtils.getDictFromJsonObject
      ->DictionaryUtils.deleteKeys(defaultFilterKeys)
    let formInitalValues =
      formState.initialValues
      ->LogicUtils.getDictFromJsonObject
      ->DictionaryUtils.deleteKeys(defaultFilterKeys)
    let dirtyFields = formState.dirtyFields->Dict.keysToArray

    let getFormattedDict = dict => {
      dict
      ->Dict.toArray
      ->Array.map(entry => {
        let (key, value) = entry
        let inputField = inputFieldsDict->Dict.get(key)->Option.getOr(defaultinputField)
        let formattor = inputField.format
        let value = switch formattor {
        | Some(fn) => fn(. ~value, ~name=key)
        | None => value
        }
        (key, value)
      })
      ->Dict.fromArray
    }

    let showApplyFilter = {
      let formattedInitialValues = formInitalValues->getFormattedDict
      let formattedCurrentValues = formCurrentValues->getFormattedDict

      let equalDictCheck = DictionaryUtils.checkEqualJsonDicts(
        formattedInitialValues,
        formattedCurrentValues,
        ~checkKeys=dirtyFields,
        ~ignoreKeys=["opt"],
      )

      let otherCheck =
        formattedCurrentValues
        ->Dict.toArray
        ->Array.reduce(true, (acc, item) => {
          let (_, value) = item
          switch value->JSON.Classify.classify {
          | String(str) => str->LogicUtils.isEmptyString
          | Array(arr) => arr->Array.length === 0
          | Object(dict) => dict->Dict.toArray->Array.length === 0
          | Null => true
          | _ => false
          } &&
          acc
        })
      !equalDictCheck && !otherCheck
    }

    // if all values are empty then don't show the apply filters let it be the clear filters visible

    if autoApply || totalFilters === 0 {
      React.null
    } else if !hideFilters && showApplyFilter {
      <div className={`flex justify-between items-center ${filterButtonStyle}`}>
        <FormRenderer.SubmitButton text="Apply Filters" icon={Button.FontAwesome("check")} />
      </div>
    } else {
      React.null
    }
  }
}

@react.component
let make = (
  ~defaultFilters,
  ~fixedFilters: array<EntityType.initialFilters<'t>>=[],
  ~requiredSearchFieldsList,
  ~setOffset=?,
  ~title="",
  ~path="",
  ~refreshFilters=true,
  ~remoteFilters: array<EntityType.initialFilters<'t>>,
  ~remoteOptions: array<EntityType.optionType<'t>>,
  ~localOptions: array<EntityType.optionType<'t>>,
  ~localFilters: array<EntityType.initialFilters<'t>>,
  ~mandatoryRemoteKeys=[],
  ~popupFilterFields: array<EntityType.optionType<'t>>=[],
  ~showRemoteOptions=false,
  ~tableName=?,
  ~autoApply=defaultAutoApply,
  ~showExtraFiltersInline=false,
  ~addFilterStyle="",
  ~filterButtonStyle="",
  ~tooltipStyling="",
  ~showClearFilterButton=false,
  ~defaultFilterKeys=[],
  ~customRightView=React.null,
  ~customLeftView=React.null,
  ~updateUrlWith=?,
  ~clearFilters=?,
  ~showClearFilter=true,
  ~filterFieldsPortalName="",
  ~initalCount=0,
  ~showFiltersBtn=false,
  ~hideFiltersDefaultValue=?,
  ~showSelectFiltersSearch=false,
  ~disableURIdecode=false,
) => {
  let {query} = React.useContext(FilterContext.filterContext)
  let alreadySelectedFiltersUserpref = `remote_filters_selected_keys_${tableName->Option.getOr("")}`
  let {addConfig} = React.useContext(UserPrefContext.userPrefContext)
  let syncIcon = "sync"

  let (selectedFiltersList, setSelectedFiltersList) = React.useState(_ =>
    remoteFilters->Array.map(item => item.field)
  )

  React.useEffect1(_ => {
    if remoteFilters->Array.length >= selectedFiltersList->Array.length {
      setSelectedFiltersList(_ => remoteFilters->Array.map(item => item.field))
    }
    None
  }, remoteFilters)

  let updatedSelectedList = React.useMemo1(() => {
    selectedFiltersList
    ->Array.map(item => {
      item.inputNames->Array.get(0)->Option.getOr("")
    })
    ->LogicUtils.getJsonFromArrayOfString
  }, [selectedFiltersList])

  React.useEffect1(() => {
    if remoteFilters->Array.length > 0 {
      addConfig(alreadySelectedFiltersUserpref, updatedSelectedList)
    }
    None
  }, [updatedSelectedList->JSON.stringify])

  let getNewQuery = DateRefreshHooks.useConstructQueryOnBasisOfOpt()
  let (isButtonDisabled, setIsButtonDisabled) = React.useState(_ => false)

  let totalFilters = selectedFiltersList->Array.length + localOptions->Array.length
  let (checkedFilters, setCheckedFilters) = React.useState(_ => [])
  let (clearFilterAfterRefresh, setClearFilterAfterRefresh) = React.useState(_ => false)
  let (count, setCount) = React.useState(_ => initalCount)

  let searchParams = query->decodeURI

  let isMobileView = MatchMedia.useMobileChecker()

  let (initialValueJson, setInitialValueJson) = React.useState(_ => JSON.Encode.object(Dict.make()))

  let countSelectedFilters = React.useMemo1(() => {
    Dict.keysToArray(initialValueJson->JSON.Decode.object->Option.getOr(Dict.make()))->Array.length
  }, [initialValueJson])
  let hideFiltersInit = switch hideFiltersDefaultValue {
  | Some(value) => value
  | _ => true
  }

  let (showModal, setShowModal) = React.useState(_ => false)
  let (hideFilters, setHideFilters) = React.useState(_ => hideFiltersInit)

  let localFilterJson = RemoteFiltersUtils.getInitialValuesFromUrl(
    ~searchParams,
    ~initialFilters=localFilters,
    (),
  )
  let clearFilterJson =
    RemoteFiltersUtils.getInitialValuesFromUrl(
      ~searchParams,
      ~initialFilters=localFilters,
      ~options=remoteOptions,
      (),
    )
    ->LogicUtils.getDictFromJsonObject
    ->Dict.keysToArray
    ->Array.length

  let popupUrlKeyArr = popupFilterFields->Array.map(item => item.urlKey)

  React.useEffect1(() => {
    let initialValues = RemoteFiltersUtils.getInitialValuesFromUrl(
      ~searchParams,
      ~initialFilters={Array.concat(remoteFilters, fixedFilters)},
      ~mandatoryRemoteKeys,
      ~options=remoteOptions,
      (),
    )
    switch updateUrlWith {
    | Some(fn) =>
      fn(
        initialValues
        ->LogicUtils.getDictFromJsonObject
        ->Dict.toArray
        ->Array.map(item => {
          let (key, value) = item
          (key, getStrFromJson(key, value))
        })
        ->Dict.fromArray,
      )
    | None => ()
    }

    switch initialValues->JSON.Decode.object {
    | Some(dict) => {
        let localCheckedFilters = Array.map(checkedFilters, filter => {
          filter
        })

        let localSelectedFiltersList = Array.map(selectedFiltersList, filter => {
          filter
        })

        dict
        ->Dict.toArray
        ->Array.forEach(entry => {
          let (key, _value) = entry
          let keyIdx = checkedFilters->Array.findIndex(item => item === key)
          if keyIdx === -1 {
            let optionObjIdx = remoteOptions->Array.findIndex(
              option => {
                option.urlKey === key
              },
            )
            if optionObjIdx !== -1 {
              let defaultEntityOptionType: EntityType.optionType<
                't,
              > = EntityType.getDefaultEntityOptionType()
              let optionObj = remoteOptions[optionObjIdx]->Option.getOr(defaultEntityOptionType)
              let optionObjUrlKey = optionObj.urlKey
              if !(popupUrlKeyArr->Array.includes(optionObjUrlKey)) {
                Array.push(localSelectedFiltersList, optionObj.field)
                Array.push(localCheckedFilters, key)
              }
            }
          }
        })
        setCount(_prev => clearFilterJson + initalCount)
        setCheckedFilters(_prev => localCheckedFilters)
        setSelectedFiltersList(_prev => localSelectedFiltersList)
        let finalInitialValueJson =
          initialValues->JsonFlattenUtils.unflattenObject->JSON.Encode.object
        setInitialValueJson(_ => finalInitialValueJson)
      }

    | None => ()
    }
    None
  }, [searchParams])

  let onSubmit = (values, _) => {
    let obj = values->JSON.Decode.object->Option.getOr(Dict.make())->Dict.toArray->Dict.fromArray

    let flattendDict = obj->JSON.Encode.object->JsonFlattenUtils.flattenObject(false)
    let localFilterDict = localFilterJson->JsonFlattenUtils.flattenObject(false)
    switch updateUrlWith {
    | Some(updateUrlWith) =>
      RemoteFiltersUtils.applyFilters(
        ~currentFilterDict=flattendDict,
        ~options=remoteOptions,
        ~defaultFilters,
        ~setOffset,
        ~path,
        ~existingFilterDict=localFilterDict,
        ~tableName,
        ~updateUrlWith,
        (),
      )
    | None =>
      RemoteFiltersUtils.applyFilters(
        ~currentFilterDict=flattendDict,
        ~options=remoteOptions,
        ~defaultFilters,
        ~setOffset,
        ~path,
        ~existingFilterDict=localFilterDict,
        ~tableName,
        (),
      )
    }

    open Promise

    setShowModal(_ => false)
    Nullable.null->resolve
  }

  let addFilters = newlyAdded => {
    let localCheckedFilters = Array.map(checkedFilters, checkedStr => {
      checkedStr
    })
    let localSelectedFiltersList = Array.map(selectedFiltersList, filter => {
      filter
    })
    newlyAdded->Array.forEach(value => {
      let optionObjArry = remoteOptions->Array.filter(option => option.urlKey === value)
      let defaultEntityOptionType: EntityType.optionType<
        't,
      > = EntityType.getDefaultEntityOptionType()
      let optionObj = optionObjArry[0]->Option.getOr(defaultEntityOptionType)
      let _ = Array.push(localSelectedFiltersList, optionObj.field)
      let _a = Array.push(localCheckedFilters, value)
    })
    setCheckedFilters(_prev => localCheckedFilters)
    setSelectedFiltersList(_prev => localSelectedFiltersList)
  }

  let removeFilters = (fieldNameArr, values) => {
    let toBeRemoved = checkedFilters->Array.filter(oldVal => !Array.includes(fieldNameArr, oldVal))
    switch values->JSON.Decode.object {
    | Some(dict) =>
      dict
      ->Dict.toArray
      ->Array.forEach(entry => {
        let (key, _val) = entry

        if toBeRemoved->Array.includes(key) {
          dict->Dict.set(key, JSON.Encode.string(""))
        }
      })
    | None => ()
    }

    let finalFieldList = selectedFiltersList->Array.filter(val => {
      val.inputNames
      ->Array.get(0)
      ->Option.map(name => !Array.includes(toBeRemoved, name))
      ->Option.getOr(false)
    })
    let filtersAfterRemoving =
      checkedFilters->Array.filter(val => !Array.includes(toBeRemoved, val))

    let newValueJson =
      initialValueJson
      ->JSON.Decode.object
      ->Option.map(Dict.toArray)
      ->Option.getOr([])
      ->Array.filter(entry => {
        let (key, _value) = entry
        !Array.includes(toBeRemoved, key)
      })
      ->Dict.fromArray
      ->JSON.Encode.object

    setInitialValueJson(_ => newValueJson)
    setCheckedFilters(_prev => filtersAfterRemoving)
    setSelectedFiltersList(_prev => finalFieldList)
  }

  let validate = values => {
    let valuesDict = values->JsonFlattenUtils.flattenObject(false)
    let errors = Dict.make()

    requiredSearchFieldsList->Array.forEach(key => {
      if Dict.get(valuesDict, key)->Option.isNone {
        let key = if key == "filters.dateCreated.lte" || key == "filters.dateCreated.gte" {
          "Date Range"
        } else {
          key
        }
        Dict.set(errors, key, "Required"->JSON.Encode.string)
      }
    })
    if errors->Dict.toArray->Array.length > 0 {
      setIsButtonDisabled(_ => true)
    } else {
      setIsButtonDisabled(_ => false)
    }
    errors->JSON.Encode.object
  }

  let fieldsFromOption = popupFilterFields->Array.map(option => {option.field})

  let handleRefresh = _ => {
    let newQueryStr = getNewQuery(
      ~queryString=query,
      ~disableFutureDates=true,
      ~disablePastDates=false,
      ~startKey="startTime",
      ~endKey="endTime",
      ~optKey="opt",
    )
    let urlValue = `${path}?${newQueryStr}`
    setClearFilterAfterRefresh(_ => true)
    setInitialValueJson(_ => Dict.make()->JSON.Encode.object)
    Window.Location.replace(urlValue)
  }

  let refreshFilterUi = {
    if refreshFilters {
      <ToolTip
        description={"Refresh the dashboard with applied settings"}
        toolTipFor={<div className={`my-1 mx-2 ${tooltipStyling} syncButton`}>
          <Button
            buttonType={SecondaryFilled}
            buttonSize=Small
            text="Refresh"
            rightIcon={FontAwesome(syncIcon)}
            onClick=handleRefresh
          />
        </div>}
        toolTipPosition=Bottom
        height="h-fit"
      />
    } else {
      React.null
    }
  }

  let isFilterSection = React.useContext(TableFilterSectionContext.filterSectionContext)
  let advancedSearchByttonType: Button.buttonType = SecondaryFilled
  let advancedSearchMargin = !isMobileView ? "ml-1" : "ml-1 mt-1"
  let verticalGap = !isMobileView ? "gap-y-2" : ""
  let filterWidth = ""
  let badge: Button.badge = {value: countSelectedFilters->Int.toString, color: BadgeBlue}

  let advacedAndClearButtons =
    <>
      <UIUtils.RenderIf
        condition={fieldsFromOption->Array.length > 0 &&
        !showExtraFiltersInline &&
        !showRemoteOptions}>
        <Portal to={`tableFilterTopRight-${title}`}>
          <div className=advancedSearchMargin>
            <Button
              text="Advanced Search"
              leftIcon=NoIcon
              buttonType=advancedSearchByttonType
              buttonSize=Small
              onClick={_ev => setShowModal(_ => true)}
              badge={countSelectedFilters > 0
                ? badge
                : {
                    value: 1->Int.toString,
                    color: NoBadge,
                  }}
            />
          </div>
        </Portal>
      </UIUtils.RenderIf>
      <UIUtils.RenderIf
        condition={!hideFilters && fixedFilters->Array.length === 0 && showClearFilter}>
        <ClearFilters
          filterButtonStyle
          defaultFilterKeys
          ?clearFilters
          count
          isCountRequired=false
          outsidefilter={initalCount > 0}
        />
      </UIUtils.RenderIf>
    </>
  let fieldWrapperClass = None
  <>
    <Form onSubmit initialValues=initialValueJson>
      <AutoSubmitter showModal autoApply submit=onSubmit defaultFilterKeys />
      {<AddDataAttributes attributes=[("data-filter", "remoteFilters")]>
        <div>
          <div className={`flex gap-2 items-center flex-wrap ${verticalGap}`}>
            {customLeftView}
            <UIUtils.RenderIf condition={fixedFilters->Array.length > 0}>
              <FormRenderer.FieldsRenderer
                fields={fixedFilters->Array.map(item => item.field)}
                labelClass="hidden"
                labelPadding="pb-2"
                ?fieldWrapperClass
              />
            </UIUtils.RenderIf>
            <UIUtils.RenderIf condition={hideFilters && isFilterSection}>
              <PortalCapture key={`customizedColumn-${title}`} name={`customizedColumn-${title}`} />
            </UIUtils.RenderIf>
            <UIUtils.RenderIf condition={showFiltersBtn}>
              <ToolTip
                description={!hideFilters
                  ? "Hide filters control panel(this will not clear the filters)"
                  : "Apply filters from exhaustive list of dimensions"}
                toolTipFor={<div className={`my-1 ${tooltipStyling} showFilterButton`}>
                  <Button
                    text={isMobileView ? "" : hideFilters ? "Show Filters" : "Hide Filters"}
                    buttonType=SecondaryFilled
                    buttonSize=XSmall
                    leftIcon=CustomIcon(
                      <Icon
                        name={hideFilters ? "show-filters" : "minus"}
                        size=14
                        className={isMobileView ? "mr-0.75" : "ml-1.5 mr-1"}
                      />,
                    )
                    onClick={_ => {
                      setHideFilters(_ => !hideFilters)
                    }}
                  />
                </div>}
                toolTipPosition={isMobileView ? BottomLeft : Right}
              />
            </UIUtils.RenderIf>
            <UIUtils.RenderIf condition={!clearFilterAfterRefresh && hideFilters && count > 0}>
              <ClearFilters
                filterButtonStyle
                defaultFilterKeys
                ?clearFilters
                count
                outsidefilter={initalCount > 0}
              />
            </UIUtils.RenderIf>
          </div>
          <div className="flex items-center">
            <div
              className={`flex ${isMobileView
                  ? "flex-wrap"
                  : "flex-row justify-between"} w-full items-center gap-2`}>
              <div
                className={`md:justify-between flex items-center flex-wrap ${filterWidth} ${addFilterStyle}`}>
                <UIUtils.RenderIf condition={!hideFilters}>
                  <div className={`flex ${!isMobileView ? "w-full" : "flex-wrap"}`}>
                    <div
                      className={`flex flex-wrap ${!isMobileView
                          ? "items-center flex-1 gap-y-2 gap-x-3 w-full"
                          : ""}`}>
                      <FormRenderer.FieldsRenderer
                        fields={selectedFiltersList} labelClass="hidden" labelPadding="pb-2"
                      />
                      <UIUtils.RenderIf condition={fixedFilters->Array.length === 0}>
                        {refreshFilterUi}
                      </UIUtils.RenderIf>
                      advacedAndClearButtons
                      <PortalCapture
                        key={`customizedColumn-${title}`} name={`customizedColumn-${title}`}
                      />
                    </div>
                  </div>
                </UIUtils.RenderIf>
              </div>
              <div className={`flex items-center justify-end flex-wrap`}>
                <div>
                  {if showExtraFiltersInline || showRemoteOptions {
                    if !hideFilters {
                      <div>
                        <CheckCustomFilters
                          options={remoteOptions}
                          checkedFilters
                          addFilters
                          removeFilters
                          showAddFilter={fieldsFromOption->Array.length > 0 ||
                            (showRemoteOptions && remoteOptions->Array.length > 0)}
                          showSelectFiltersSearch
                        />
                      </div>
                    } else {
                      React.null
                    }
                  } else {
                    React.null
                  }}
                </div>
                {!hideFilters ? customRightView : React.null}
                <ApplyFilterButton
                  autoApply
                  totalFilters
                  hideFilters
                  filterButtonStyle
                  defaultFilterKeys
                  selectedFiltersList
                />
                {if showClearFilterButton && !hideFilters && count > 0 {
                  <ClearFilters
                    filterButtonStyle
                    defaultFilterKeys
                    ?clearFilters
                    count
                    outsidefilter={initalCount > 0}
                  />
                } else {
                  React.null
                }}
              </div>
            </div>
          </div>
        </div>
      </AddDataAttributes>}
    </Form>
    <LabelVisibilityContext showLabel=true>
      <TableFilterSectionContext isFilterSection=false>
        <Form onSubmit validate initialValues=initialValueJson>
          <ModalUI showModal setShowModal initialValueJson fieldsFromOption isButtonDisabled />
        </Form>
      </TableFilterSectionContext>
    </LabelVisibilityContext>
  </>
}
