open NewAnalyticsTypes

let getPageIndex = (url: RescriptReactRouter.url) => {
  switch url.path->HSwitchUtils.urlPath {
  | list{"new-analytics-payment"} => 1
  | _ => 0
  }
}

let getPageFromIndex = index => {
  switch index {
  | 1 => NewAnalyticsPayment
  | _ => NewAnalyticsOverview
  }
}

let tabs: array<Tabs.tab> = [
  {
    title: "Overview",
    renderContent: () => <OverViewAnalytics />,
  },
  {
    title: "Payments",
    renderContent: () => <div className="mt-5"> {"Payments page"->React.string} </div>,
  },
]