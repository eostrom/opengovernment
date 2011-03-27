$(document).ready(function() {
  var chart = new Highcharts.Chart({
    chart: {
      renderTo: 'contributions_chart',
      defaultSeriesType: 'scatter'
    },

    series: [
      {
        data: points
      }
    ],
    xAxis: {
      min: 0
    },
    yAxis: {
      min: 0
    }
  });
});
