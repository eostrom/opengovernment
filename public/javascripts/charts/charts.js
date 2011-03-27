$(document).ready(function() {
  var formatMoney = function(n, c, d, t){
    var c = isNaN(c = Math.abs(c)) ? 2 : c,
      d = d == undefined ? "." : d,
      t = t == undefined ? "," : t,
      s = n < 0 ? "-" : "",
      i = parseInt(n = Math.abs(+n || 0).toFixed(c)) + "",
      j = (j = i.length) > 3 ? j % 3 : 0;

   return s + (j ? i.substr(0, j) + t : "") +
        i.substr(j).replace(/(\d{3})(?=\d)/g, "$1" + t) +
        (c ? d + Math.abs(n - i).toFixed(c).slice(2) : "");
 };

  var points = $.map(contributions, function(person) {
    return {
      x: person.contributions_count,
      y: person.contributions_sum,
      name: person.first_name + ' ' + person.last_name,
      events: {
        click: function() {
          window.location = person.permalink;
        }
      }
    };
  });

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
    tooltip: {
      formatter: function(i) {
        var point = this.point;

        return '<b>' + point.name + '</b>: ' +
          point.x + ' contributions, $' + formatMoney(point.y, 0);
      }
    },
    xAxis: {
      min: 0
    },
    yAxis: {
      min: 0
    }
  });
});
