module RawHBarChart = {
  @react.component
  let make = (~options: JSON.t) => {
    <HighchartsHorizontalBarChart.HBarChart
      highcharts={HighchartsHorizontalBarChart.highchartsModule} options
    />
  }
}
open HighchartsHorizontalBarChart

let valueFormatter = (
  @this
  (this: tooltipRecord) => {
    `<div class='text-white'>${this.category} count: <b>${this.y->Int.toString}</b></div>`
  }
)->asTooltipPointFormatter

let dataLabelFormatter: yAxisRecord => string = (
  @this
  _param => {
    ""
  }
)->asDataLabelFormatter

let xLabelFormatter: xAxisRecord => string = (
  @this
  param => {
    let axis = param.axis
    let series = axis.series
    let value = param.value
    let seriesSum =
      series
      ->Array.map(series => {
        let options = series.options
        switch options {
        | Some(options) => options.data
        | None => []
        }->Array.reduce(0, (acc, num) => {acc + num})
      })
      ->Array.reduce(0, (acc, num) => {acc + num})
    let index = Array.findIndex(axis.categories, x => {x === value})
    let firstSeries = series->Array.get(0)
    let y = switch firstSeries {
    | Some(series) => {
        let options = series.options
        switch options {
        | Some(options) => options.data->Array.get(index)->Option.getOr(0)
        | None => 0
        }
      }

    | None => 0
    }
    `<div style="display: inline-block; margin-left: 10px;" class="text-black dark:text-white"><div class="font-semibold"> ${value} </div><div class="font-medium" style="display: inline-block;">` ++
    (y->Float.fromInt *. 100. /. seriesSum->Float.fromInt)
      ->Float.toFixedWithPrecision(~digits=2) ++ `%</div></div>`
  }
)->asXLabelFormatter

@react.component
let make = (
  ~rawData: array<JSON.t>,
  ~groupKey,
  ~titleKey=?,
  ~selectedMetrics: LineChartUtils.metricsConfig,
) => {
  let {globalUIConfig: {primaryColor}, theme} = React.useContext(ThemeProvider.themeContext)
  let barChartData = React.useMemo(() => {
    LineChartUtils.chartDataMaker(
      ~filterNull=true,
      rawData,
      groupKey,
      selectedMetrics.metric_name_db,
    )
  }, (rawData, groupKey, selectedMetrics.metric_name_db))
  let titleKey = titleKey->Option.getOr(groupKey)

  let barOption: JSON.t = React.useMemo(() => {
    let colors = {
      let length = barChartData->Array.length->Int.toFloat
      barChartData->Array.mapWithIndex((_data, i) => {
        let i = i->Int.toFloat
        let opacity = (length -. i +. 1.) /. (length +. 1.)
        `rgb(var(--color-${primaryColor}),${opacity->Float.toString})`
      })
    }
    let defaultOptions: HighchartsHorizontalBarChart.options = {
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
          name: `${titleKey->LogicUtils.snakeToTitle} Share`,
          data: barChartData->Array.map(data => {
            let (_, y) = data
            y
          }),
          \"type": "bar",
        },
      ],
      plotOptions: Some({
        bar: {
          dataLabels: {
            enabled: true,
            formatter: dataLabelFormatter,
            useHTML: true,
          },
          colors,
          colorByPoint: true,
          borderColor: theme === Dark ? "black" : "white",
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
        \"type": "bar",
        backgroundColor: theme === Dark ? "#202124" : "white",
      },
      xAxis: {
        categories: barChartData->Array.map(data => {
          let (x, _) = data
          x
        }),
        lineWidth: 0,
        opposite: true,
        labels: {
          enabled: true,
          formatter: xLabelFormatter,
          useHTML: true,
        },
      },
      yAxis: {
        min: 0,
        title: {
          text: "category",
        },
        labels: {
          enabled: false,
        },
        gridLineWidth: 0,
        visible: false,
      },
      legend: {
        enabled: false,
      },
    }
    defaultOptions->Identity.genericTypeToJson
  }, (barChartData, theme))

  <RawHBarChart options=barOption />
}
