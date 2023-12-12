open DayJs
open DateRangeUtils
let useConstructQueryOnBasisOfOpt = () => {
  let customTimezoneToISOString = TimeZoneHook.useCustomTimeZoneToIsoString()
  let isoStringToCustomTimeZone = TimeZoneHook.useIsoStringToCustomTimeZone()
  let isoStringToCustomTimezoneInFloat = TimeZoneHook.useIsoStringToCustomTimeZoneInFloat()
  let todayDayJsObj = Js.Date.make()->Js.Date.toString->getDayJsForString

  let todayDate = todayDayJsObj.format(. "YYYY-MM-DD")
  let todayTime = todayDayJsObj.format(. "HH:mm:ss")
  (~queryString, ~disableFutureDates, ~disablePastDates, ~startKey, ~endKey, ~optKey) => {
    if queryString->Js.String2.includes(optKey) {
      try {
        let arrQuery = queryString->Js.String2.split("&")
        let tempArr = arrQuery->Js.Array2.filter(x => x->Js.String2.includes(optKey))
        let tempArr = tempArr[0]->Belt.Option.getWithDefault("")->Js.String2.split("=")
        let optVal = tempArr[1]->Belt.Option.getWithDefault("")

        let customrange: customDateRange = switch optVal {
        | "today" => Today
        | "yesterday" => Yesterday
        | "tomorrow" => Tomorrow
        | "last_month" => LastMonth
        | "this_month" => ThisMonth
        | "next_month" => NextMonth
        | st => {
            let arr = st->Js.String2.split("_")
            let _ = arr[0]->Belt.Option.getWithDefault("") == "next"
            let anchor = arr[2]->Belt.Option.getWithDefault("")
            let val = arr[1]->Belt.Option.getWithDefault("")
            switch anchor {
            | "days" => Day(val->Belt.Float.fromString->Belt.Option.getWithDefault(0.0))
            | "hours" => Hour(val->Belt.Float.fromString->Belt.Option.getWithDefault(0.0))
            | "mins" => Hour(val->Belt.Float.fromString->Belt.Option.getWithDefault(0.0) /. 60.0)
            | _ => Today
            }
          }
        }
        let (stDate, enDate, stTime, enTime) = getPredefinedStartAndEndDate(
          todayDayJsObj,
          isoStringToCustomTimeZone,
          isoStringToCustomTimezoneInFloat,
          customTimezoneToISOString,
          customrange,
          disableFutureDates,
          disablePastDates,
          todayDate,
          todayTime,
        )
        let stTimeStamp = changeTimeFormat(
          ~date=stDate,
          ~time=stTime,
          ~customTimezoneToISOString,
          ~format="YYYY-MM-DDTHH:mm:ss.SSS[Z]",
        )
        let enTimeStamp = changeTimeFormat(
          ~date=enDate,
          ~time=enTime,
          ~customTimezoneToISOString,
          ~format="YYYY-MM-DDTHH:mm:ss.SSS[Z]",
        )
        let updatedArr = arrQuery->Js.Array2.map(x =>
          if x->Js.String2.includes(startKey) {
            `${startKey}=${stTimeStamp}`
          } else if x->Js.String2.includes(endKey) {
            `${endKey}=${enTimeStamp}`
          } else {
            x
          }
        )
        updatedArr->Js.Array2.joinWith("&")
      } catch {
      | _error => queryString
      }
    } else {
      queryString
    }
  }
}
