%%raw(`require("./highcharts.css")`)
module RawPieChart = {
  @react.component
  let make = (~options: JSON.t) => {
    <HighchartsPieChart.PieChart highcharts={HighchartsPieChart.highchartsModule} options />
  }
}
open HighchartsPieChart

let valueFormatter = (
  @this
  (this: tooltipRecord) => {
    `<div class='text-white'>${this.name} count: <b>${this.y->Int.toString}</b></div>`
  }
)->asTooltipPointFormatter

let formatter: yAxisRecord => string =
  (
    @this
    param =>
      `<div class="font-semibold text-black dark:text-white">` ++
      param.point.name ++
      `</div><br><div class="font-medium text-black dark:text-white">` ++
      param.point.percentage->Float.toFixedWithPrecision(~digits=2) ++ `%</div>`
  )->asDataLabelFormatter

@react.component
let make = (
  ~rawData: array<JSON.t>,
  ~groupKey,
  ~titleKey=?,
  ~selectedMetrics: LineChartUtils.metricsConfig,
) => {
  let {globalUIConfig: {primaryColor}, theme} = React.useContext(ThemeProvider.themeContext)
  let pieSeriesData = React.useMemo3(() => {
    LineChartUtils.chartDataMaker(
      ~filterNull=true,
      rawData,
      groupKey,
      selectedMetrics.metric_name_db,
    )
  }, (rawData, groupKey, selectedMetrics.metric_name_db))
  let color = theme === Dark ? "white" : "black"
  let borderColor = theme === Dark ? "black" : "white"
  let opacity = theme === Dark ? "0.5" : "1"
  let titleKey = titleKey->Option.getOr(groupKey)

  let barOption: JSON.t = React.useMemo2(() => {
    let colors = {
      let length = pieSeriesData->Array.length->Int.toFloat
      pieSeriesData->Array.mapWithIndex((_data, i) => {
        let i = i->Int.toFloat
        let opacity = (length -. i +. 1.) /. (length +. 1.)
        `${primaryColor},${opacity->Float.toString})`
      })
    }
    let defaultOptions: HighchartsPieChart.options = {
      title: {
        text: `<div class='font-semibold text-lg font-inter-style text-black dark:text-white'>${titleKey->LogicUtils.snakeToTitle}</div>`,
        align: "Left",
        useHTML: true,
      },
      subtitle: {
        text: `<div class='font-medium text-sm font-inter-style text-jp-gray-800 dark:text-dark_theme'>Distribution across ${titleKey->LogicUtils.snakeToTitle}s</div>`,
        align: "Left",
        useHTML: true,
      },
      series: [
        {
          \"type": "pie",
          name: `${titleKey->LogicUtils.snakeToTitle} Share`,
          innerSize: "58%",
          data: pieSeriesData,
        },
      ],
      plotOptions: Some({
        pie: {
          dataLabels: {
            enabled: true,
            connectorShape: "straight",
            formatter,
            style: {
              color,
              opacity,
            },
            useHTML: true,
          },
          startAngle: -90,
          endAngle: 90,
          center: ["50%", "75%"],
          size: "100%",
          colors,
          borderColor,
        },
      }),
      credits: {enabled: false},
      tooltip: {
        pointFormatter: valueFormatter,
        useHTML: true,
        backgroundColor: "#ffffff",
        borderColor: "#E5E5E5",
        headerFormat: "",
      },
      chart: {
        backgroundColor: theme === Dark ? "#202124" : "white",
      },
    }
    defaultOptions->Identity.genericTypeToJson
  }, (pieSeriesData, theme))

  <RawPieChart options=barOption />
}
